class CreateChannels < ActiveRecord::Migration[6.0]
  def change
    create_table :channels do |t|
      t.string :slack_channel_id, null: false
      t.string :reaction_id, null: false
      t.string :org_repo, null: false
      t.string :labels

      t.timestamps
    end

    add_index :channels, [:slack_channel_id, :reaction_id], unique: true
  end
end
