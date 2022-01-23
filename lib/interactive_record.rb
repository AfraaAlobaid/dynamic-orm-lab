require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        col_names = []
        table_info = DB[:conn].execute("PRAGMA table_info('#{table_name}');")
        table_info.each do |col_info|
            col_names << col_info["name"]
        end

        col_names.compact
    end

    def initialize(options = {})
        options.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end
    
    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        #values = []
        self.class.column_names.delete_if{|col| col == "id"}.map do |col| 
            "'#{self.send(col)}'" unless self.send(col).nil? 
        end.join(", ")
    end

    def save
        #DB[:conn].results_as_hash = false
        sql = <<-SQL
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
            VALUES (#{values_for_insert});
            SQL
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert};")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{table_name} WHERE name = ?;", name)
    end

    def self.find_by(att)
        string_att = att.map {|key, value| "#{key} = '#{value}'" }.join(", ")
        sql = <<-SQL
            SELECT * FROM #{table_name}
            WHERE #{string_att};
            SQL
        DB[:conn].execute(sql)
    end
end