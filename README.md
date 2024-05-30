# TinkersTools

A set of unique tools for D&D 5e players and DMs. 

## notes

**This is a work in progress and is not ready for use.**

Right now most of the work is done in the scratches folder. The scraper.exs file was created from repl iterations and can be used to scrape data from the D&D 5e wikidot. Some spells have issues due to inconsistencies with data formatting, but this is not something that needs to be run often and can be fixed manually when adding to the database. This file will be integrated into the main codebase in the future. 

The spells.sql file is a ddl script to generate the spells table. I am working on moving my database over to a docker-compose setup, but for now the databse can be configured with this one table in the dnd5e schema. 

The first tool that I am working on creating with this is a spell components page that will allow users to select the spells that their characters know, this will compile a list of spell components that the user needs to buy in their game. Additionally, it should indiciate whether a spell consumes its materital components or not and notify the user in case they want to buy more.  

Other tools that will come later are a wild shape recommender that will allow users to filter on the features they want in a wild shape and filter down what's best. I would also like to create a deck of many things tracker that allows DMs to create a deck of many things (custom or canon) and then track the progress of the deck as the players draw cards. Ideally this would also include a way to find additional decks from other users on the site. 

Eventually I would like to expand the scope of this tool beyond just D&D 5e. 