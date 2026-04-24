class RemoveCourseInfoFromGradebookCategories < ActiveRecord::Migration[4.2]
  def self.up
    # useful pattern if we actually had data in these tables
    #sql = 'INSERT INTO course_gradebook_categories(gradebook_category_id, course_id, rank, is_archived) ' +
    #      'SELECT id, course_id, rank, is_archived FROM gradebook_categories;'
    #ActiveRecord::Base.connection.execute(sql)
    remove_column :gradebook_categories, :course_id
    remove_column :gradebook_categories, :rank
  end

  def self.down
    add_column :gradebook_categories, :course_id, :integer
    add_column :gradebook_categories, :rank, :default => 1

    # useful pattern if we actually had data in these tables
    #sql = 'SELECT gc.name, cgc.course_id, cgc.rank, cgc.is_archived' + 
    #      'FROM   course_gradebook_categories cgc ' +
    #      'INNER JOIN gradebook_categories gc on gc.id = cgc.gradebook_category_id;'
    #old_records = ActiveRecord::Base.connection.execute(sql)
    #old_records.each do |record|
    #  sql = "INSERT INTO gradebook_categories(name, course_id, rank, is_archived) " +
    #        "VALUES('#{record.name}', #{record.course_id}, #{record.rank}, #{record.is_archived});"
    #  ActiveRecord::Base.connection.execute(sql) 
    #end
  end
end
