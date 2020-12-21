# ElasticSearch cheatsheet

Elasticsearch cheatsheet and quickstart study guide

[curl](#curl)

1. [mapping](#mapping)
1. [insert](#insert)
1. [bulk-insert](#bulk-insert)
1. [query](#query)

[Misc](#misc)
1. [docker](#docker)

# curl

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

## query
```bash
./curl  -XGET 127.0.0.1:9200/movies/_search\?pretty
```

# misc

## Docker

```bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.1
```

