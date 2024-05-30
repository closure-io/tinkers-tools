defmodule TinkersTools.DnD5e.Resources.Spell do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "dnd5e"
  @primary_key {:name, :string, autogenerate: false}

  @spell_schools ["abjuration", "conjuration", "divination", "enchantment", "evocation", "illusion", "necromancy", "transmutation"]
  @spell_levels [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  schema "spells" do
    field(:source, :string)
    field(:type, :string)
    field(:school, :string)
    field(:level, :integer)
    field(:casting_time, :string)
    field(:range, :string)
    field(:comp_verbal, :boolean)
    field(:comp_somatic, :boolean)
    field(:comp_material, :boolean)
    field(:materials, :string)
    field(:duration, :string)
    field(:concentration, :boolean)
    field(:description, :string)
    field(:spell_lists, :map)
    field(:costly_components, :boolean)
    field(:materials_breakdown, :map)

    timestamps()
  end

  def changeset(spell, params \\ %{}) do
    spell
    |> cast(params, [:name, :source, :type, :school, :level, :casting_time, :range, :comp_verbal, :comp_somatic, :comp_material,
    :materials, :duration, :concentration, :description, :spell_lists, :costly_components, :materials_breakdown])
    |> validate_required([:name, :source, :type, :school, :level, :casting_time, :range, :comp_verbal, :comp_somatic, :comp_material,
    :materials, :duration, :concentration, :description, :spell_lists])
    |> validate_inclusion(:school, @spell_schools)
    |> validate_inclusion(:level, @spell_levels)
  end
end
