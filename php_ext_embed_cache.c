/*
   +----------------------------------------------------------------------+
   | PHP Embeddable Ext Project                                           |
   +----------------------------------------------------------------------+
   | Copyright (c) 1997-2014 The PHP Group                                |
   +----------------------------------------------------------------------+
   | This source file is subject to version 3.01 of the PHP license,      |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | http://www.php.net/license/3_01.txt                                  |
   | If you did not receive a copy of the PHP license and are unable to   |
   | obtain it through the world-wide-web, please send a note to          |
   | license@php.net so we can mail you a copy immediately.               |
   +----------------------------------------------------------------------+
   | Authors: Shen Jiale <jerryshen.zju@gmail.com>                        |
   +----------------------------------------------------------------------+
*/

#include <php.h>
#include <zend.h>
#include <zend_API.h>

/* Main idea came from eAccelerator */

HashTable embed_global_function_table;
HashTable embed_global_class_table;

Bucket *function_table_tail;
Bucket *class_table_tail;
HashTable* orig_function_table;
HashTable* orig_class_table;
HashTable* orig_eg_class_table;

void php_embed_cache_restore()
{
    function_table_tail = function_table_tail ? function_table_tail->pListNext : embed_global_function_table.pListHead;
    class_table_tail = class_table_tail ? class_table_tail->pListNext : embed_global_class_table.pListHead;

    while (function_table_tail != NULL) {
        zend_op_array *op_array = (zend_op_array*)function_table_tail->pData;
        if (op_array->type == ZEND_USER_FUNCTION) {
            if (zend_hash_add(CG(function_table), function_table_tail->arKey, function_table_tail->nKeyLength, op_array, sizeof(zend_op_array), NULL) == FAILURE &&
                function_table_tail->arKey[0] != '\0') {
                // CG(in_compilation) = 1;
                // CG(compiled_filename) = file_handle->opened_path;
                // CG(zend_lineno) = op_array->line_start;
                zend_error(E_ERROR, "Cannot redeclare %s()", function_table_tail->arKey);
            }
        }
        function_table_tail = function_table_tail->pListNext;
    }

    while (class_table_tail != NULL) {
        zend_class_entry **ce = (zend_class_entry**)class_table_tail->pData;
        if ((*ce)->type == ZEND_USER_CLASS) {
            if (zend_hash_add(CG(class_table), class_table_tail->arKey, class_table_tail->nKeyLength, ce, sizeof(zend_class_entry*), NULL) == FAILURE &&
                class_table_tail->arKey[0] != '\0') {
                // CG(in_compilation) = 1;
                // CG(compiled_filename) = file_handle->opened_path;
                // #ifdef ZEND_ENGINE_2_4
                // CG(zend_lineno) = (*ce)->info.user.line_start;
                // #else
                // CG(zend_lineno) = (*ce)->line_start;
                // #endif
                zend_error(E_ERROR, "Cannot redeclare class %s", class_table_tail->arKey);
            }
        }
        class_table_tail = class_table_tail->pListNext;
    }
}

void php_embed_compile_string_init()
{
    zend_hash_init(&embed_global_function_table, 32, NULL, ZEND_FUNCTION_DTOR, 1);
    orig_function_table = CG(function_table);
    CG(function_table) = &embed_global_function_table;

    zend_hash_init(&embed_global_class_table, 10, NULL, ZEND_CLASS_DTOR, 1);
    orig_class_table = CG(class_table);;
    CG(class_table) = &embed_global_class_table;
    orig_eg_class_table = EG(class_table);;
    EG(class_table) = &embed_global_class_table;

    function_table_tail = CG(function_table)->pListTail;
    class_table_tail = CG(class_table)->pListTail;
}

void php_embed_compile_string_finish()
{
    CG(function_table) = orig_function_table;
    CG(class_table) = orig_class_table;
    EG(class_table) = orig_eg_class_table;
}
