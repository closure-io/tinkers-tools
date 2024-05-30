defmodule Scraper do
  use HTTPoison.Base

  def process_url(url), do: url
  def process_response_body(body), do: body |> Floki.parse_document
end

defmodule SpellDescription do
  @schools ["abjuration", "conjuration", "divination", "enchantment", "evocation", "illusion", "necromancy", "transmutation"]
  def get_description(html_body) do
    # Locate the parent element that contains the description and the list
    [{"div", [{"id", "page-content"}], children}] = Floki.find(html_body, "div#page-content")

    # Adjusting the slice range to capture all relevant elements
    relevant_children = Enum.slice(children, 4..-3)

    # Combine the text from paragraphs and list items in the desired format
    relevant_children
    |> Enum.flat_map(&process_element/1)
    |> Enum.join("\n")
  end

  defp process_element({"p", _, inner_text}), do: [Floki.text(inner_text)]
  defp process_element({"ul", _, items}), do: Enum.flat_map(items, &process_element/1)
  defp process_element({"li", _, [{"strong", _, [{"em", _, [text]}]} | rest]}), do: [text <> ". " <> Floki.text(rest)]
  defp process_element({"li", _, rest}), do: [Floki.text(rest)]  # <-- Handling list items without a strong tag
  defp process_element(_), do: []

  def get_title(spell_html_body) do
    Floki.find(spell_html_body, ".page-title.page-header span") |> Floki.text
  end

  def get_school(spell_html_body) do
    spell_type = spell_html_body
    |> Floki.find("p")
    |> Enum.at(1)
    |> Floki.text()
    |> String.downcase()

    Enum.find(@schools, &String.contains?(spell_type, &1))
  end

  def get_level(spell_html_body) do
    spell_type = spell_html_body
    |> Floki.find("p")
    |> Enum.at(1)
    |> Floki.text()
    |> String.downcase()

    if String.contains?(spell_type, "cantrip") do
      0
    else
      Regex.run(~r/(\d+)(?:st|nd|rd|th)-level/, spell_type, capture: :all_but_first)
      |> List.first()
      |> String.to_integer()
    end
  end

  def verbal_comp?(input) do
    "V" in input
  end

  def somatic_comp?(input) do
    "S" in input
  end

  def material_comp?(input) do
    "M" in input
  end

  def split_spell_components(input) when input == "", do: []

  def split_spell_components(input) do
    input
    |> String.split(~r/\(/, trim: true)
    |> Enum.at(0)
    |> String.split(~r/\,/, trim: true)
    |> Enum.map(&String.trim/1)
  end

  def get_spell_materials(input) do
    comps = input
    |> String.split(~r/\(/, trim: true, parts: 2)

    case length(comps) do
      1 -> ""
      2 ->
        materials = comps |> List.last()
        if String.ends_with?(materials, ")") do
          String.replace_suffix(materials, ")", "")
        else
          materials
        end
    end
  end

  def get_duration(input) do
    duration_pos = case get_title(input) do
      "Draconic Transformation (UA)" -> 4
      _ -> 3
    end
    Regex.run(~r/(?<=Duration:<\/strong>\s).*/, input
      |> Floki.find("p")
      |> Enum.at(2)
      |> Floki.raw_html()
      |> String.split(~r/<br\/>/)
      |> Enum.at(duration_pos)
    )
    |> Enum.at(0)
    |> String.replace("</p>", "")
  end

  def is_concentration?(input) do
    String.contains?(input |> get_duration() |> String.downcase(), "concentration")
  end

  def get_spell_lists(input) do
    spell_lists_list = input
    |> Floki.find("p")
    |> Enum.take(-1)
    |> Floki.find("a")
    |> Enum.map(&Floki.text/1)

    %{"spell_lists": spell_lists_list}
  end
end

alias TinkersTools.Repo
alias

schools = ["abjuration", "conjuration", "divination", "enchantment", "evocation", "illusion", "necromancy", "transmutation"]
levels = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

# Usage:
# description = SpellDescription.get_description(spell_html_body)

base_url = "http://dnd5e.wikidot.com/spells"
{:ok, doc} = Scraper.get(base_url)
{:ok, doc_body} = doc.body
["html", xml_headers, html_res] = doc_body |> Enum.at(0) |> Tuple.to_list
[html_headers, html_body] = html_res
# Floki.find(html_body, "a[href^='/spell:']") # raw
spell_paths = Floki.find(html_body, "a[href^='/spell:']") |> Floki.attribute("href") # all spell urls

# build spell urls
spell_urls = spell_paths |> Enum.map(&("http://dnd5e.wikidot.com#{&1}"))

# spells
spell_url = "http://dnd5e.wikidot.com/spell:gate-seal"
{:ok, spell_doc} = Scraper.get(spell_url)
{:ok, spell_doc_body} = spell_doc.body
["html", spell_xml_headers, spell_html_res] = spell_doc_body |> Enum.at(0) |> Tuple.to_list
[spell_html_headers, spell_html_body] = spell_html_res
spell_comps = Regex.run(~r/(?<=Components:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(2)) |> Enum.at(0) |> SpellDescription.split_spell_components()

alias TinkersTools.DnD5e.Resources.Spell

spell = %Spell{
      name: spell_html_body |> SpellDescription.get_title(),
      source: spell_html_body |> Floki.find("p") |> Enum.at(0) |> Floki.text(),
      type: spell_html_body |> Floki.find("p") |> Enum.at(1) |> Floki.text(),
      school: spell_html_body |> SpellDescription.get_school(),
      level: spell_html_body |> SpellDescription.get_level(),
      casting_time: Regex.run(~r/(?<=Casting Time:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(0)) |> Enum.at(0),
      range: Regex.run(~r/(?<=Range:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(1)) |> Enum.at(0),
      comp_verbal: spell_comps |> SpellDescription.verbal_comp?(),
      comp_somatic: spell_comps |> SpellDescription.somatic_comp?(),
      comp_material: spell_comps |> SpellDescription.material_comp?(),
      materials: Regex.run(~r/(?<=Components<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(2)) |> Enum.at(0) |> SpellDescription.get_spell_materials(),
      duration: spell_html_body |> SpellDescription.get_duration(),
      concentration: spell_html_body |> SpellDescription.is_concentration?(),
      description: SpellDescription.get_description(spell_html_body),
      # at_higher_levels: spell_html_body |> Floki.find("p") |> Enum.at(4) |> Floki.text(),
      spell_lists: spell_html_body |> SpellDescription.get_spell_lists()
}

require Logger

test_urls = Enum.take(spell_urls, 150)

# PLEASE READ
# Gate Seal and Antagonize are both broken and should be removed from the full URLs list and added manually.

broken_spells = [
  "http://dnd5e.wikidot.com/spell:gate-seal",
  "http://dnd5e.wikidot.com/spell:antagonize"
]

spell_urls_sans_broken_spells = Enum.filter(spell_urls, fn url ->
  url not in broken_spells
end)

res = Enum.map(spell_urls_sans_broken_spells, fn spell ->
  {:ok, spell_doc} = Scraper.get(spell)
  {:ok, spell_doc_body} = spell_doc.body
  ["html", spell_xml_headers, spell_html_res] = spell_doc_body |> Enum.at(0) |> Tuple.to_list
  [spell_html_headers, spell_html_body] = spell_html_res
  spell_comps = Regex.run(~r/(?<=Components:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(2)) |> Enum.at(0) |> SpellDescription.split_spell_components()

  try do
    spell = %Spell{
      name: spell_html_body |> SpellDescription.get_title(),
      source: spell_html_body |> Floki.find("p") |> Enum.at(0) |> Floki.text(),
      type: spell_html_body |> Floki.find("p") |> Enum.at(1) |> Floki.text(),
      school: spell_html_body |> SpellDescription.get_school(),
      level: spell_html_body |> SpellDescription.get_level(),
      casting_time: Regex.run(~r/(?<=Casting Time:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(0)) |> Enum.at(0),
      range: Regex.run(~r/(?<=Range:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(1)) |> Enum.at(0),
      comp_verbal: spell_comps |> SpellDescription.verbal_comp?(),
      comp_somatic: spell_comps |> SpellDescription.somatic_comp?(),
      comp_material: spell_comps |> SpellDescription.material_comp?(),
      materials: Regex.run(~r/(?<=Components:<\/strong>\s).*/, spell_html_body |> Floki.find("p") |> Enum.at(2) |> Floki.raw_html() |> String.split(~r/<br\/>/) |> Enum.at(2)) |> Enum.at(0) |> SpellDescription.get_spell_materials(),
      duration: spell_html_body |> SpellDescription.get_duration(),
      concentration: spell_html_body |> SpellDescription.is_concentration?(),
      description: SpellDescription.get_description(spell_html_body),
      # at_higher_levels: spell_html_body |> Floki.find("p") |> Enum.at(4) |> Floki.text(),
      spell_lists: spell_html_body |> SpellDescription.get_spell_lists()
    }

    Repo.insert(spell)

  rescue
    e in FunctionClauseError ->
      spell_name = Floki.find(spell_html_body, ".page-title.page-header span") |> Floki.text
      Logger.debug(e)
      Logger.debug("Failed spell: #{spell_name}")
      ""
    e in Ecto.ConstraintError ->
      spell_name = Floki.find(spell_html_body, ".page-title.page-header span") |> Floki.text
      Logger.debug(e)
      Logger.debug("Spell primary key error: #{spell_name}")
      ""
    e in _ ->
      spell_name = Floki.find(spell_html_body, ".page-title.page-header span") |> Floki.text
      Logger.debug(e)
      Logger.debug("Failed spell: #{spell_name}")
      ""
  end
end)

# Enum.map(res, &Repo.insert/1)
