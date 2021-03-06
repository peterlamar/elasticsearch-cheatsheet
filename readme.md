# ElasticSearch cheatsheet

Elasticsearch cheatsheet and quickstart study guide

[Concepts](#concepts)

1. [Documents](#documents)
1. [Indices](#indices)
1. [Nodes](#nodes)
1. [Shards](#shards)
1. [Use Cases](#use-cases)


[curl](#curl)

1. [Backup index](#backup-index)
1. [List index mapping](#list-index-mapping)
1. [Delete index](#delete-index)
1. [List indexes](#list-indexes)
1. [Mapping](#mapping)
1. [Analyzers](#analyzers)
1. [NGram](#ngram)
1. [Insert](#insert)
1. [Bulk-insert](#bulk-insert)
1. [Update](#update)
1. [Delete](#delete)
1. [Get](#get)
1. [Cluster Status](#cluster-status)
1. [List Masters](#list-masters)

[Search](#search)

1. [Match](#match)
1. [Fuzzy](#fuzzy)
1. [Prefix](#prefix)
1. [Wildcard](#wildcard)
1. [Match Phrase](#match-phrase)
1. [Match Phrase Prefix](#match-phrase-prefix)
1. [Filters](#filters)
1. [Query lite search](#query-lite)
1. [Pagination](#pagination)
1. [Sort](#sort)

[Misc](#misc)
1. [Docker](#docker)

# concepts

## Documents

Things you are searching for, can be any text but typically json. Each document has a unique ID, version and type. A document is kind of like a row in a database. 

Example:

```
{
  "name": "Elastic",
  "location": "somewhere",
  "data": [1,2]
}
```

Example response after posting to ES index:

```
{
  "_index": "myindex",
  "_type": "_doc",
  "_id": "ndskdf239dkD",
  "_version": 1,
  "result": "created:,
  "_shards": {
    "total": 2,
    "successful": 1,
    "failed": 0
  }
  "_seq_no": 21,
  "_primary_term" : 1
}
```

## Indices

Also called an inverted index, basically the lookup table in the back of a book

```
Document 1:

Space: The final frontier. These are the voyages

Document 2:

He's bad, he's number one. He's the space cowboy with the laser gun!

Inverted index

space:    1,2
the:      1,2
final:    1
frontier: 1
he:       2
bad:      2
```

Indexes can be created for you or you can create them manually. 

Example index create
```
PUT /inspections
{
  "settings": {
    "index.number_of_shards": 1,
    "index.number_of_replicas": 0
  }
}
```

Each index has a "number_of_shards" value to pertains to that index. Five primary shards and one replica created by default for each index.

## Nodes

Nodes are servers added to a cluster to increase capacity

## Shards

Shards are self-contained Lucene indexes. Documents in an index can be distributed across multiple shards (10 documents per shard for example). Shards can be distributed across multiple nodes. As cluster grows or shrinks Elasticsearch migrates shards to rebalance cluster

There are two types of shards, primaries and replicas and each document belongs to a primary shard. Only the primary shard can accept indexing requests but both can [accept query requests](https://www.youtube.com/watch?v=aG6WPu08qBs). 

The number of primary shards in an index is fixed at index creation time but replicas can be changed at any time. Number of shards can be considered similar to disk partition. 

Shards are allocated based on dataset growth expectations. 

Each shard:
1. Consumes file handles, memory and CPU resources
1. Each search request touches a copy of every shard
1. Problems can happen when shards compete for the same hardware resource
1. More shards has lower document [relevance](https://www.elastic.co/blog/practical-bm25-part-1-how-shards-affect-relevance-scoring-in-elasticsearch)

Performance considerations:
1. Queries are sent to each shard simultaneuously and then the results are aggregated. More I/O headroom and multicore processor can benefit from sharding. 
1. More shards involves more maintenence overhead
1. Larger shards mean longer cluster rebalance times
1. Querying small shards makes processing per shard faster
1. More queries involves more overhead, so a smaller number of large shards maybe faster.

Advice:
1. Ideal scenario is one shard per index per node
1. Starting point for cluster planning, allocate shards with a factor of 1.5 to 3 times the number of nodes in the initial configuration. So if starting with 3 nodes then max 9 shards
1. Recommended shard size 1GB < x < 40GB, with common sizes 20GB < x < 40GB. Divide expected data size by number of shards to reach reasonable number. For example, 200GB of data then have 7 shards at approx 30GB each
1. Number of shards per GB of heap space should be less than 20
1. Max JVM Heap Size recommendation for Elasticsearch = 30-32GB

Performance Experiments
1. [Elastic cluster sizing](https://www.elastic.co/elasticon/conf/2016/sf/quantitative-cluster-sizing)

## Use-Cases

1. Logstash - Accumilating daily indices, incurring small search loads

If left with the default of 5 primary shards for every index (double if to include the default replica), then after six months there could be 5 x 30 x 6 = 890 shards which would require > 15 nodes (Roughly 60 primary shards per node or approx 15 shards for each GB of heap space assumed to be 4 for primary shards and 4 for the replicas)

A custom setting of 1 shard per node with a single replica will be 180 shards in six months which is more managable

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

## Analyzers

1. Use [standard analyzer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-standard-analyzer.html) if none is specified
1. Character Filters: Remove HTML encoding, convert & to and
1. Tokenizer: Split strings on whitespace/punctiation/non-letters
1. Token Filter: Lowercasing, stemming, synonyms, stopwords
1. Standard: split on word boundaries, remove punctuation, lowercases, good if language is unknown
1. Simple: Split on anything that isn't a letter, and lowercase
1. Whitespace: Splits on whitespace but doesn't lowercase
1. Language: Accounts for language-specific stopwords and stemming

Test analyzer
```bash
./curl -XGET 127.0.0.1:9200/movies/_analyze\?pretty -d '{
    "analyzer": "autocomplete",
    "text": "Sta"
}'
```

Specify analyzer
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{
    "query":{
        "match":{
            "title":{
                "query":"sta",
                "analyzer":"standard"
            }
        }
    }
}'
```

## NGram

Custom analyzer 'autocomplete'
```bash
./curl -XPUT 127.0.0.1:9200/movies -d '{
    "settings":{
        "analysis":{
            "filter":{
                "autocomplete_filter": {
                    "type":"edge_ngram",
                    "min_gram":1,
                    "max_gram":20
                }
            },
        "analyzer":{
            "autocomplete":{
                "type":"custom", 
                "tokenizer":"standard",
                "filter": [
                    "lowercase",
                    "autocomplete_filter"
                ]
                }
            }
        }
    }
}'
```

Assign analyzer as mapping
```bash
./curl -XPUT '127.0.0.1:9200/movies/_mapping?pretty' -d '
{
    "properties": {
        "title":{
            "type":"text",
            "analyzer":"autocomplete"
        }
    }
}
'
```

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

## Get

Get movie with ID 109487
```bash
./curl  -XGET 127.0.0.1:9200/movies/_doc/109487\?pretty
```

## Cluster Status

```
./curl  -XGET 192.168.86.23:9200/_cluster/stats\?pretty
```

## List Masters

```
./curl  -XGET "192.168.86.23:9200/_cat/master?v=true&pretty"
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

## Match

```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match":{"title":"star"}}}'
```
## Fuzzy
Fuzzy defaults
* 0 for 1-2 character strings
* 1 for 3-5 character strings
* 2 for anything else

Allow 1 character off
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"fuzzy":{"title":{"value":"intersteller","fuzziness":1}}}}'
```

## Prefix
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"prefix":{"year":"201"}}}'
```

## Wildcard
```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"wildcard":{"year":"1*"}}}'
```

## Match Phrase

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

## Match Phrase Prefix
Can be used to implement autocomplete

```bash
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"query":{"match_phrase_prefix":{"title":{"query":"star"}}}}'
```

## Filters

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

## pagination
* Pagination results are still retrieved, but sorted and o mitted before returning to user

```bash
./curl -XGET '127.0.0.1:9200/movies/_search?size=2&from=2&pretty'
./curl -XGET 127.0.0.1:9200/movies/_search\?pretty -d '{"from": 2, "size": 2, "query":{"match":{"genre":"Sci-Fi"}}}'
```

When from is omitted it starts from 0
```bash
./curl -XGET '127.0.0.1:9200/movies/_search?size=2&pretty'
```

## sort
* A string field that is analyzed for full text search cannot be used to sort documents since it exists in the inverted index as individual terms

```bash
./curl -XGET '127.0.0.1:9200/movies/_search?sort=year&pretty'
```

A copy of a field could be made so allow full text search and raw sorting
```bash
./curl -XPUT 127.0.0.1:9200/movies/ -d '{
    "mappings": {
        "properties" : {
            "title": {
                "type":"text",
                "fields":{
                    "raw":{
                        "type":"keyword"
                    }
                }
            }
        }
    }
}'
./curl -XGET '127.0.0.1:9200/movies/_search?sort=title.raw&pretty'
```

* Cannot change mapping on an existing index. Would have to delete it, setup mapping and reindex

# misc

## Docker

```bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.1
```

# Reference

[Content](https://learning.oreilly.com/api/v1/continue/9781788995122/) from OReilly course
