require 'bulk_insert/worker'

module BulkInsert
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_insert(*columns, values: nil, set_size: 500, ignore: false, update_duplicates: false, return_primary_keys: false, return_keys: nil)
      columns = default_bulk_columns if columns.empty?
      worker = BulkInsert::Worker.new(connection, table_name, primary_key, columns, set_size, ignore, update_duplicates, return_primary_keys, return_keys)

      if values.present?
        transaction do
          worker.add_all(values)
          worker.save!
        end
        return worker if return_primary_keys
        nil
      elsif block_given?
        transaction do
          yield worker
          worker.save!
        end
        return worker if return_primary_keys
        nil
      else
        worker
      end
    end

    # helper method for preparing the columns before a call to :bulk_insert
    def default_bulk_columns
      self.column_names - %w(id)
    end

  end
end

ActiveSupport.on_load(:active_record) do
  send(:include, BulkInsert)
end
