defmodule TinkersTools.DnD5e.Resources.TestTable do
  use Ecto.Schema

  @schema_prefix "dnd5e"
  @primary_key false

  schema "test_table" do
    field :c1, :integer
    field :c2, :string
    field :c3, :string
    timestamps()
  end
end
