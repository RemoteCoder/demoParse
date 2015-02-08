class CreateUserDetails < ActiveRecord::Migration
  def change
    create_table :user_details do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :street
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :job_service_name
      t.float :price
      t.integer :cycle
      t.date :next_job_at
      t.boolean :field_valid_status
      t.string :note

      t.timestamps
    end
  end
end
