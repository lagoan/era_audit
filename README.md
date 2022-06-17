# era_audit

## Reports description

+ Report 1: Metadata only records
+ Report 2: List of file types
+ Report 3: List of records containing compressed files
+ Report 4: List of all multi file records
+ Report 5: List of records missing a required metadata filed
+ Report 6: List of all community-collection pairs and all items within collections
+ Report 7: List of all empty collections, listing community-collection pairs
+ Report 8: List CCID-protected items
+ Report 9: List of embargoed items including embargo lift date
+ Report 10: Items with QDC descriptive metadata
+ Report 11: Items with ETD-MS descriptive metadata
+ Report 12: Items with community-collection path that does not exist
+ Report 13: List of communities with no description (community name, URL)
+ Report 14: List of communities with no logo image (community name, URL)
+ Report 15: List of collections with 5 or fewer items (collection name, URL)
+ Report 16: List of collections with no description (collection name, URL)
+ Report 17: List of communities with no collections (community name, URL)

## Reports assumptions

These reports are intended to be from a very high level and their purpose is to
find errors that will be fixed when migrating to DSpace. The following are
assumptions made for these reports:

+ Report 3: List of records containing compressed files - This report was initially requested for zip files, but after further discussions with the metadata team it was expanded to include all compressed files gathered from the report of the file types contained in the system.
+ Report 4: List of all multi file records - This report includes records with multiple filesets associations but no information about the files themselves.
+ Report 5: List of records missing a required metadata filed. This report is generated with 2 types of validation. The first step is to validate the item with the `valid?` method for the model. This however does not check for models t
+ Report 6: List of all community-collection pairs and all items within collections - This report lists all the items from the community-collection pairs and it is important to note that there may be items that do not show up as they could be considered orphans.
+ Report 10: Items with QDC descriptive metadata - From the system, this is a list of all entities with the Item model.
+ Report 11: Items with ETD-MS descriptive metadata - From the system, this is a list of all entities with the Thesis model.
+ Report 12: Items with community-collection path that does not exist. This report checks if the member of paths value has information of a non existing Community, Collection, or the Community-Collection pair.

