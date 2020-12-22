# ElasticSearch cheatsheet

Elasticsearch cheatsheet and quickstart study guide

[curl](#curl)

1. [backup index]($backup-index)
1. [list index mapping](#list-index-mapping)
1. [delete index](#delete-index)
1. [list indexes](#list-indexes)
1. [mapping](#mapping)
1. [insert](#insert)
1. [bulk-insert](#bulk-insert)
1. [update](#update)
1. [delete](#delete)
1. [search](#search)
1. [filters](#filters)
1. [query lite search](#query-lite)
1. [get](#get)

[Misc](#misc)
1. [docker](#docker)

# curl

## Backup-index

```bash
curl -XPOST --header 'Content-Type: application/json' http://localhost:9200/_reindex -d '{
  "source": {
    "index": "samples"
  },
  "dest": {
    "index": "samples_backup"
  }
}'
```

## List-Index-Mapping

List the fields and their types in an index
```bash
curl -X GET http://localhost:9200/samples
```

## Delete-Index

```bash
curl -X DELETE 'http://localhost:9200/samples'
```

## List Indexes

```bash
curl -X GET 'http://localhost:9200/_cat/indices?v'
```

## List docs in index

```bash
curl -X GET 'http://localhost:9200/sample/_search'
```

## Mapping

Mappings are schema definitions that customize defaults. 

```bash
./curl -XPUT 127.0.0.1:9200/movies -d '
{
    "mappings":{
        "properties":{
            "year":{"type":"date"}
        }
    }
}'
```

Field Types: String, Byte, Short, Integer, Long, Float, Double, Boolean, Date
```bash
./curl -XPUT 127.0.0.1:9200/movies -d '
{
    "mappings":{
        "properties":{
            "user_id":{"type":"long"}
        }
    }
}'
```

Index field for full-text search?
```bash
./curl -XPUT 127.0.0.1:9200/movies -d '
{
    "mappings":{
        "properties":{
            "genre":{"index":"not_analyzed"}
        }
    }
}'
```

Make genre type keyword so its not analyzed (matches other cases, etc)
```bash
./curl -XPUT 127.0.0.1:9200/movies -d '
{
    "mappings":{
        "properties": {
            "id": {"type":"date"},
            "year":{"type":"date"},
            "genre":{"type":"keyword"},
            "title":{"type":"text","analyzer":"english"}
        }
    }
}
'
```

Map film to franchise to make a parent
```bash
./curl -XPUT 127.0.0.1:9200/series -d '
{"mappings":{
    "properties":{
        "film_to_franchise":{
            "type":"join","relations":{
                "franchise":"film"
                }}}}
    }'
```

Analyzers:
1. Character Filters: Remove HTML encoding, convert & to and
1. Tokenizer: Split strings on whitespace/punctiation/non-letters
1. Token Filter: Lowercasing, stemming, synonyms, stopwords
1. Standard: split on word boundaries, remove punctuation, lowercases, good if language is unknown
1. Simple: Split on anything that isn't a letter, and lowercase
1. Whitespace: Splits on whitespace but doesn't lowercase
1. Language: Accounts for language-specific stopwords and stemming

## insert

Insert record
```bash
./curl -XPUT 127.0.0.1:9200/movies/_doc/109487 -d '
{
    "genre":
    ["IMAX","Sci-Fi"],
    "title":"Interstellar",
    "year":2014
}'
```

```bash
curl -XPUT --header 'Content-Type: application/json' http://localhost:9200/samples/_doc/1 -d '{
   "school" : "Harvard"			
}'
```

## bulk-insert

```bash
./curl -XPUT 127.0.0.1:9200/_bulk\?pretty --data-binary @movies.json
```

## update
Each document has a _version firle and is immutable
When you update an existing document, a new document is created with an incremented _version and then the old document is marked for deletion

```
./curl -XPOST 127.0.0.1:9200/movies/_doc/109487/_update -d '
{
    "doc" :{
    "title":"Interstellarxx"
    }
}
'
```

Insert and Update
```bash
curl -XPUT --header 'Content-Type: application/json' http://localhost:9200/samples/_doc/2 -d '
{
    "school": "Clemson"
}'
curl -XPOST --header 'Content-Type: application/json' http://localhost:9200/samples/_doc/2/_update -d '{
"doc" : {
               "students": 50000}
}'
```

## delete
```bash
curl -XDELETE 127.0.0.1:9200/movies/_doc/58559
```

## search

Queries are wrapped in a "query": { } block

Query Types
* Match all: Returns all documents and is default. Formally used with a filter
```json
{"match_all":{}}
```
* Match: Searches analyzed results, such as full text search
```json
{"match":{"title":"star"}}
```
* Multi-match: Run the same query on multiple fields
```json
{"multi_match":{"query":"star","fields":["title","synopsis"]}}
```
* Bool: Works like a bool filterm but results are scored by relevance
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '
{
    "query":{
        "bool": {
            "must":{"term":{"title":"trek"}},
            "filter":{"range":{"year":{"gte":2010}}}
        }
    }
}'
```


Get all movies
```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?pretty
```

```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?q=dark
```

Match
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match":{"title":"star"}}}'
```

Match Phrase (order and lettering)
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match_phrase":{"title":"star wars"}}}'
```

Match Phrase
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match_phrase":{"genre":"sci"}}}'
```

Match Phrase with Slop which allows term to move in either direction 
* enables star beyond to match Star Trek Beyond (also beyond star)
* enables "quick brown fox" to match "quick fox" with a slop of 1
* If slop of 100 is specified, then any document with 'star' or 'beyond' within 100 words could be returned, but closer values are returned with higher relevance
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match_phrase":{"title":{"query":"star beyond", "slop": 1}}}}'
```

Find films whose parent matches "Star Wars"
./curl  -XGET 127.0.0.1:9200/series/_search\?pretty -d '
{"query":{
    "has_parent":{
        "parent_type":"franchise",
        "query":{
            "match":{
                "title":"Star Wars"}
        }
    }
}
}'

Find franchise associated with a film
```bash
./curl  -XGET 127.0.0.1:9200/series/_search\?pretty -d '
{"query":{
    "has_child":{
        "type":"film",
        "query":{
            "match":{
                "title":"The Force Awakens"}
        }
    }
}
}
'
```
## Filter

Filters are wrapped in a "filter": { } block

Types of Filters
* Term: Filter by exact values
```json
{"term":{"year":2014}}
```
* Terms: Match if any exact values in a list match
```json
{"terms":{"genre":["Sci-Fi","Adventure"]}}
```
* Range: Find numbers or dates in a given range (gt, gte, lt, lte)
```json
{"range":{"year":{"gte": 2010}}}
```
* Exists: Find documents where a field exists
```json
{"exists":{"fields":"tags"}}
```
* Missing: Find documents where a field is missing
```json
{"missing":{"field":"tags"}}
```
* Bool: Combine filters with Boolean logic (must, must_not, should)

## Query Lite

Compared to json queries, can be:
1. Cryptic
1. Security vulnerabile
1. Fragile

Get movie with title star
```bash
./curl  -XGET '127.0.0.1:9200/movies/_search?q=title:star&pretty=true'
```

Request body equivalent

```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{
    "query":{
        "match":{
            "title":"star"
        }
    }
}'

```

Released after 2010 with Trek in the title
```bash
./curl  -XGET '127.0.0.1:9200/movies/_search?q=+year>2010+title:trek&pretty=true'
```

Request body equivalent
```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?pretty -d '
{
    "query":{
        "bool":{
            "must":{"term": {"title":"trek"}},
            "filter":{"range":{"year":{"gte":2010}}}
        }
    }
}'
```


## Get

Get movie with ID 109487
```bash
./curl  -XGET 127.0.0.1:9200/movies/_doc/109487\?pretty
```

# misc

## Docker

```bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.1
```

