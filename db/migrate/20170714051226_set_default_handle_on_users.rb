# Sets a handle for users without one
class SetDefaultHandleOnUsers < ActiveRecord::Migration[5.1]
  def up
    Authify::API::Models::User.reset_column_information
    Authify::API::Models::User.all.each do |user|
      tmp_handle = Authify::API::Models::User.uniq_handle_generator(user.full_name, user.email)
      user.handle = tmp_handle unless user.handle
      puts "Setting handle #{user.handle} for User #{user.id}"
      user.save
    end
  end

  def down
    # nothing to do
  end
end
