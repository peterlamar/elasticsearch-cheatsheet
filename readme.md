# ElasticSearch cheatsheet

Elasticsearch cheatsheet and quickstart study guide

[curl](#curl)

1. [delete index](#delete-index)
1. [list indexes](#list-indexes)
1. [mapping](#mapping)
1. [insert](#insert)
1. [bulk-insert](#bulk-insert)
1. [update]
1. [query](#query)

[Misc](#misc)
1. [docker](#docker)

# curl

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

Define Tokenizer and token filter: standrd/whitespace/simple/english/etc
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

## query

Get all movies
```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?pretty
```

Get movie with ID 109487
```bash
./curl  -XGET 127.0.0.1:9200/movies/_doc/109487\?pretty
```

# misc

## Docker

```bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.1
```

