defmodule TestApp.Repo.Migrations.AddUserInfo do
  use Ecto.Migration

  def change do
    alter table(:users_info) do
      add :dob, :date
      add :gender, :string
      add :address, :string


    end

  end
end
