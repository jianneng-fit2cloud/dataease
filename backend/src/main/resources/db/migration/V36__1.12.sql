ALTER TABLE `dataset_table_field`
    ADD COLUMN `path` varchar(255) NULL COMMENT '树路径' AFTER `column_index`;