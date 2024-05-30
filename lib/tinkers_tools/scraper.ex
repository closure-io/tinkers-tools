defmodule TinkersTools.Dnd5e.Scraper do
  use HTTPoison.Base

  def process_url(url), do: url
  def process_response_body(body), do: body |> Floki.parse_document
end
