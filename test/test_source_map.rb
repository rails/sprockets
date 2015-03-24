require 'minitest/autorun'
require 'sprockets/source_map'

class TestSourceMap < MiniTest::Test
  Map = Sprockets::SourceMap

  def setup
    @mappings = Map.new([
      {source: 'a.js', generated: [0, 0], original: [0, 0]},
      {source: 'b.js', generated: [1, 0], original: [20, 0]},
      {source: 'c.js', generated: [2, 0], original: [30, 0]}
    ])
  end

  def test_map
    hash = {
      'version' => 3,
      'file' => "script.min.js",
      'mappings' => "AAEAA,QAASA,MAAK,EAAG,CACfC,OAAAC,IAAA,CAAY,eAAZ,CADe",
      'sources' => ["script.js"],
      'names' => ["hello", "console", "log"]
    }
    map = Map.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 1, mapping[:generated][0]
    assert_equal 0, mapping[:generated][1]
    assert_equal 3, mapping[:original][0]
    assert_equal 0, mapping[:original][1]
    assert_equal 'script.js', mapping[:source]
    assert_equal 'hello', mapping[:name]

    assert mapping = map.mappings[-1]
    assert_equal 1, mapping[:generated][0]
    assert_equal 45, mapping[:generated][1]
    assert_equal 3, mapping[:original][0]
    assert_equal 17, mapping[:original][1]
    assert_equal 'script.js', mapping[:source]
    assert_equal nil, mapping[:name]

    assert_equal hash['sources'],  map.as_json['sources']
    assert_equal hash['names'],    map.as_json['names']
    assert_equal hash['mappings'], map.as_json['mappings']

    assert_equal hash, map.as_json
    assert_equal hash.to_json, map.to_json
    assert_equal hash.to_json, JSON.generate(map)
  end

  def test_map2
    hash = {
      'version' => 3,
      'file' => "example.js",
      'mappings' => ";;;;;EACAA;;EACAC;;EAGA;IAAA;;;EAGAC;IAAS;;;EAGTC;;EAGAC;IACE;IACA;IACA;MAAQ;;;;EAGVC;;;IACE;;;EAGF;IAAA;;;EAGAC;;;IAAQ;;MAAA",
      'sources' => ["example.coffee"],
      'names' => ["number", "opposite", "square", "list", "math", "race", "cubes"]
    }
    map = Map.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 6, mapping[:generated][0]
    assert_equal 2, mapping[:generated][1]
    assert_equal 2, mapping[:original][0]
    assert_equal 0, mapping[:original][1]
    assert_equal 'example.coffee', mapping[:source]
    assert_equal 'number', mapping[:name]

    assert mapping = map.mappings[-1]
    assert_equal 43, mapping[:generated][0]
    assert_equal 6, mapping[:generated][1]
    assert_equal 28, mapping[:original][0]
    assert_equal 8, mapping[:original][1]
    assert_equal 'example.coffee', mapping[:source]
    assert_equal nil, mapping[:name]

    assert_equal hash['sources'],  map.as_json['sources']
    assert_equal hash['names'],    map.as_json['names']
    assert_equal hash['mappings'], map.as_json['mappings']

    assert_equal hash, map.as_json
    assert_equal hash.to_json, map.to_json
    assert_equal hash.to_json, JSON.generate(map)
  end

  def test_map3
    hash = {
      'version' => 3,
      'file' => "example.min.js",
      'mappings' => "AACC,SAAQ,EAAG,CAAA,IACCA,CADD,CACOC,CADP,CACaC,CADb,CAC0CC,CAWpDA,EAAA,CAASA,QAAQ,CAACC,CAAD,CAAI,CACnB,MAAOA,EAAP,CAAWA,CADQ,CAIrBJ,EAAA,CAAO,CAAC,CAAD,CAAI,CAAJ,CAAO,CAAP,CAAU,CAAV,CAAa,CAAb,CAEPC,EAAA,CAAO,MACCI,IAAAC,KADD,QAEGH,CAFH,MAGCI,QAAQ,CAACH,CAAD,CAAI,CAChB,MAAOA,EAAP,CAAWD,CAAA,CAAOC,CAAP,CADK,CAHb,CAcc,YAArB,GAAI,MAAOI,MAAX,EAA8C,IAA9C,GAAoCA,KAApC,EACEC,KAAA,CAAM,YAAN,CAGO,UAAQ,EAAG,CAAA,IACdC,CADc,CACVC,CADU,CACJC,CACdA,EAAA,CAAW,EACNF,EAAA,CAAK,CAAV,KAAaC,CAAb,CAAoBX,CAAAa,OAApB,CAAiCH,CAAjC,CAAsCC,CAAtC,CAA4CD,CAAA,EAA5C,CACER,CACA,CADMF,CAAA,CAAKU,CAAL,CACN,CAAAE,CAAAE,KAAA,CAAcb,CAAAM,KAAA,CAAUL,CAAV,CAAd,CAEF,OAAOU,EAPW,CAAX,CAAA,EApCC,CAAX,CAAAG,KAAA,CA8CO,IA9CP",
      'sources' => ["example.js"],
      'names' => ["list","math","num","square","x","Math","sqrt","cube","elvis","alert","_i","_len","_results","length","push","call"]
    }
    map = Map.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 1, mapping[:generated][0]
    assert_equal 0, mapping[:generated][1]
    assert_equal 2, mapping[:original][0]
    assert_equal 1, mapping[:original][1]
    assert_equal 'example.js', mapping[:source]
    assert_equal nil, mapping[:name]

    assert mapping = map.mappings[-1]
    assert_equal 1, mapping[:generated][0]
    assert_equal 289, mapping[:generated][1]
    assert_equal 2, mapping[:original][0]
    assert_equal 1, mapping[:original][1]
    assert_equal 'example.js', mapping[:source]
    assert_equal nil, mapping[:name]

    assert_equal hash['sources'],  map.as_json['sources']
    assert_equal hash['names'],    map.as_json['names']
    assert_equal hash['mappings'], map.as_json['mappings']

    assert_equal hash, map.as_json
    assert_equal hash.to_json, map.to_json
    assert_equal hash.to_json, JSON.generate(map)
  end

  def test_eql
    map1 = @mappings
    map2 = @mappings.dup
    map3 = Map.new([
      {source: 'a.js', generated: [0, 0], original: [0, 0]},
      {source: 'b.js', generated: [1, 0], original: [20, 0]},
      {source: 'c.js', generated: [2, 0], original: [30, 0]}
    ])
    map4 = Map.new
    map5 = Map.new([
      {source: 'a.js', generated: [0, 0], original: [0, 0]}
    ])
    map6 = Map.new([
      {source: 'a.js', generated: [0, 0], original: [0, 0]},
      {source: 'b.js', generated: [1, 0], original: [20, 0]},
      {source: 'z.js', generated: [2, 0], original: [30, 0]}
    ])
    map7 = Map.new([
      {source: 'a.js', generated: [0, 0], original: [0, 0]},
      {source: 'b.js', generated: [1, 0], original: [20, 0]},
      {source: 'c.js', generated: [2, 0], original: [30, 0]}
    ], 'bar.js')

    assert map1.eql?(map1)
    assert map1.eql?(map2)
    assert map1.eql?(map3)

    refute map1.eql?(true)
    refute map1.eql?(map4)
    refute map1.eql?(map5)
    refute map1.eql?(map6)
    refute map1.eql?(map7)
  end

  def test_add
    mappings2 = Map.new([
      {source: 'd.js', generated: [0, 0], original: [0, 0]}
    ])
    mappings3 = @mappings + mappings2
    assert_equal 0, mappings3.mappings[0][:generated][0]
    assert_equal 1, mappings3.mappings[1][:generated][0]
    assert_equal 2, mappings3.mappings[2][:generated][0]
    assert_equal 3, mappings3.mappings[3][:generated][0]
  end

  def test_add_identity
    identity_map = Map.new

    assert_equal @mappings, identity_map + @mappings
    assert_equal @mappings, @mappings + identity_map
  end

  def test_pipe
    mappings1 = Map.from_json(%{
      {
        "version": 3,
        "file": "index.js",
        "sourceRoot": "",
        "sources": [
          "index.coffee"
        ],
        "names": [],
        "mappings": ";AAAA;AAAA,MAAA,IAAA;;AAAA,EAAA,IAAA,GAAO,SAAA,GAAA;WACL,KAAA,CAAM,aAAN,EADK;EAAA,CAAP,CAAA;;AAGA,EAAA,IAAW,IAAX;AAAA,IAAG,IAAH,CAAA,CAAA,CAAA;GAHA;AAAA"
      }
    })

    mappings2 = Map.from_json(%{
      {
        "version":3,
        "file":"index.min.js",
        "sources":["index.js"],
        "names":["test","alert","call","this"],
        "mappings":"CACA,WACE,GAAIA,KAEJA,MAAO,WACL,MAAOC,OAAM,eAGf,IAAI,KAAM,CACRD,SAGDE,KAAKC"
      }
    })

    mappings3 = mappings1 | mappings2
    assert_equal 'CAAA,WAAA,GAAA,KAAA,MAAO,WAAA,MACL,OAAM,eAER,IAAW,KAAX,CAAG,SAHH,KAAA', mappings3.as_json["mappings"]
  end

  def test_pipe_identity
    identity_map = Map.new

    assert_equal @mappings, identity_map | @mappings
  end
end
