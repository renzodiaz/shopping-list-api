class CreateJwtBlocklists < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_blocklists do |t|
      t.string :jti
      t.datetime :exp

      t.timestamps
    end
  end
end
