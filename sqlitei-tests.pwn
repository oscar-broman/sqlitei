#include <a_samp>
#define DB_DEBUG false
#include "sqlitei"

stock const
	gc_DbFile[] = "sqlitei-tests.db"
;

main() {
	new DB:db, buf[512], value, Float:float_value, DBResult:result;
	
	fremove(gc_DbFile);
	
	if ((db = db_open(gc_DbFile))) {
		if (!db_exec(db, !"CREATE TABLE `test` (a, b, c, d, e)"))
			print(!"Failed to run query: \"CREATE TABLE `test` (a, b, c, d, e)\".");
		
		if ((value = db_query_int(db, !"SELECT 0")) != 0) printf("db_query_int: %d != %d", value, 0);
		if ((value = db_query_int(db, !"SELECT 1")) != 1) printf("db_query_int: %d != %d", value, 1);
		if ((value = db_query_int(db, !"SELECT 2147483647")) != 2147483647) printf("db_query_int: %d != %d", value, 2147483647);
		if ((value = db_query_int(db, !"SELECT 2147483648")) != 2147483648) printf("db_query_int: %d != 2147483648", value);
		
		if ((float_value = db_query_float(db, !"SELECT 5231.572331")) != 5231.572331) printf("db_query_float: %f != %f", float_value, 5231.572331);
		if ((float_value = db_query_float(db, !"SELECT -5231.572331")) != -5231.572331) printf("db_query_float: %f != %f", float_value, -5231.572331);
		
		result = db_query(db, !"SELECT 10");
		
		if (db_is_result_freed(result)) print(!"db_is_result_freed should be false");
		
		db_free_result(result);
		
		if (!db_is_result_freed(result)) print(!"db_is_result_freed should be true");
		
		result = db_query(db, !"SELECT NULL, 0, NULL, 1, NULL, 2, NULL");
		
		if (!db_field_is_null(result, 0)) print(!"db_field_is_null(x, 0): should be true");
		if ( db_field_is_null(result, 1)) print(!"db_field_is_null(x, 1): should be false");
		if (!db_field_is_null(result, 2)) print(!"db_field_is_null(x, 2): should be true");
		if ( db_field_is_null(result, 3)) print(!"db_field_is_null(x, 3): should be false");
		if (!db_field_is_null(result, 4)) print(!"db_field_is_null(x, 4): should be true");
		if ( db_field_is_null(result, 5)) print(!"db_field_is_null(x, 5): should be false");
		if (!db_field_is_null(result, 6)) print(!"db_field_is_null(x, 6): should be true");
		
		db_free_result(result);
		
		{
			new str[] = "ö\'döå2ål0FKNVALIHƒßå˚∫œ∆†¥∫©¡";
			
			for (new i = 0; i < 2; i++) {
				if (i == 1)
					strpack(str, str);
				
				result = db_query(db, !"SELECT ?", STRING:str);
		
				db_get_field(result, 0, buf, sizeof(buf));
		
				if (strlen(buf) != strlen(str) || strcmp(buf, str))
					print(!"buf != str");
			
				for (new j = 0; str{j}; j++) {
					if (buf[j] != str{j})
						printf("buf[%d]:%04x%04x != str{%d}:%04x%04x", j, buf[j] >>> 16, buf[j] & 0xFFFF, j, str{j} >>> 16, str{j} & 0xFFFF);
				}
			
				db_free_result(result);
			
				result = db_query(db, !"SELECT ? as `test`", STRING:str);
		
				db_get_field_assoc(result, !"test", buf, sizeof(buf));
		
				if (strlen(buf) != strlen(str) || strcmp(buf, str))
					print(!"buf != str");
			
				for (new j = 0; str{j}; j++) {
					if (buf[j] != str{j})
						printf("buf[%d]:%04x%04x != str{%d}:%04x%04x", j, buf[j] >>> 16, buf[j] & 0xFFFF, j, str{j} >>> 16, str{j} & 0xFFFF);
				}
			}
		}
		
		{
			new
				DBStatement:stmt = db_prepare(db, !"SELECT ?, ?, ?, ?"),
				array[128]
			;
			
			for (new j = 0; j < sizeof(array); j++)
				array[j] = random(256) << 24 | random(256) << 16 | random(256) << 8 | random(256);
			
			value = cellmin;
			float_value = 19634.56729164;
			
			for (new i = 0; i < sizeof(buf) - 1; i++)
				buf[i] = 1 + (i % 255);
			
			stmt_bind_value(stmt, 0, DB::TYPE_INT,    value);
			stmt_bind_value(stmt, 1, DB::TYPE_FLOAT,  float_value);
			stmt_bind_value(stmt, 2, DB::TYPE_ARRAY,  array, sizeof(array));
			stmt_bind_value(stmt, 3, DB::TYPE_STRING, buf);
			
			new
				r_value,
				Float:r_float_value,
				r_array[sizeof(array)],
				r_buf[sizeof(buf)]
			;
			
			stmt_bind_result_field(stmt, 0, DB::TYPE_INT   , r_value);
			stmt_bind_result_field(stmt, 1, DB::TYPE_FLOAT , r_float_value);
			stmt_bind_result_field(stmt, 2, DB::TYPE_ARRAY , r_array, sizeof(r_array));
			stmt_bind_result_field(stmt, 3, DB::TYPE_STRING, r_buf, sizeof(r_buf));
			
			if (stmt_execute(stmt)) {
				if (stmt_fetch_row(stmt)) {
					if (value != r_value)
						printf("value:%d != r_value:%d", value, r_value);
					
					if (float_value != r_float_value)
						printf("float_value:%04x%04x != r_float_value:%04x%04x", _:float_value >>> 16, _:float_value & 0xFFFF, _:r_float_value >>> 16, _:r_float_value & 0xFFFF);
					
					for (new j = 0; j < sizeof(array); j++) {
						if (array[j] != r_array[j])
							printf("array[%d]:%04x%04x != r_array[%d]:%04x%04x", j, array[j] >>> 24, array[j] & 0xFFFF, j, r_array[j] >>> 24, r_array[j] & 0xFFFF);
					}
					
					if (strlen(buf) != strlen(r_buf) || strcmp(buf, r_buf))
						print(!"buf != r_buf");
					
					for (new j = 0; j < sizeof(buf); j++) {
						if (buf[j] != r_buf[j])
							printf("buf[%d]:%04x%04x != r_buf[%d]:%04x%04x", j, buf[j] >>> 16, buf[j] & 0xFFFF, j, r_buf[j] >>> 16, r_buf[j] & 0xFFFF);
					}
				} else {
					print("stmt has no rows.");
				}
			} else {
				print(!"Failed to execute stmt.");
			}
		}
		
		for (new i = 1; i <= 10; i++) {
			new rowid;
			
			if (!(rowid = db_insert(db, !"INSERT INTO `test` VALUES (1, 'two', 3.4, 'five', 6.7)"))) {
				print(!"Failed to run query: \"INSERT INTO `test` VALUES (1, 'two', 3.4, 'five', 6.7)\".");
			} else {
				if (rowid != i)
					printf("rowid: %d != %d", rowid, i);
				else if ((rowid = db_query_int(db, !"SELECT last_insert_rowid()"))) {
					if (rowid != i)
						printf("last_insert_rowid(): %d != %d", rowid, i);
				} else {
					print(!"Failed to run query: \"SELECT last_insert_rowid()\".");
				}
			}
		}
		
		db_close(db);
	} else {
		printf("Failed to open database (\"%s\").", gc_DbFile);
	}
	
	print(!"Done.");
}