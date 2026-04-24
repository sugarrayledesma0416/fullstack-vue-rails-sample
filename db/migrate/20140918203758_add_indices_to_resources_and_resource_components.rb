class AddIndicesToResourcesAndResourceComponents < ActiveRecord::Migration[4.2]
  def change
    add_index :resources, :resource_component_id, name: 'by_resource_component'
    add_index :resource_components, :program_id, name: 'by_program'
  end
end

## To optimize this query
# SELECT resource_components.* 
# FROM `resource_components` 
# INNER JOIN `resources` ON `resources`.`resource_component_id` = `resource_components`.`id` 
# WHERE `resource_components`.`program_id` = 53 
# GROUP BY resource_components.id

## EXPLAIN Before adding index
# id     select_type     table                type     possible_keys     key      key_len     ref                                 rows     Extra                           
# -----  --------------  -------------------  -------  ----------------  -------  ----------  ----------------------------------  -------  ------------------------------- 
# 1      SIMPLE          resources            ALL      (null)            (null)   (null)      (null)                              23028    Using temporary; Using filesort 
# 1      SIMPLE          resource_components  eq_ref   PRIMARY           PRIMARY  4           m3.resources.resource_component_id  1        Using where                     

