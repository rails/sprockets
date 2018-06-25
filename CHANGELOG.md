**Master**

Get upgrade notes from Sprockets 3.x to 4.x at https://github.com/rails/sprockets/blob/master/UPGRADING.md

## Master

## 4.0.0.beta8

- Security release for [CVE-2018-3760](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3760)

## 4.0.0.beta7

- Fix a year long bug that caused `Sprockets::FileNotFound` errors when the asset was present [#547]
- Raise an error when two assets such as foo.js and foo.js.erb would produce the same output artifact (foo.js) [#549 #530]
- Process `*.jst.eco.erb` files with ERBProcessor

## 4.0.0.beta6

- Fix source map line offsets [#515]
- Return a `400 Bad Request` when the path encoding is invalid. [#514]

## 4.0.0.beta5

- Reduce string allocations
- Source map metadata uses compressed form specified by the [source map v3 spec](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k). [#402] **[BREAKING]**
- Generate [index maps](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit#heading=h.535es3xeprgt) when decoding source maps isn't necessary. [#402]
- Remove fingerprints from source map files. [#402]

## 4.0.0.beta4

- Changing the version now busts the digest of all assets [#404]
- Exporter interface added [#386]
- Using ENV vars in templates will recompile templates when the env vars change. [#365]
- Source maps for imported sass files with sassc is now fixed [#391]
- Load paths now in error messages [#322]
- Cache key added to babel processor [#387]
- `Environment#find_asset!` can now be used to raise an exception when asset could not be found [#379]

## 4.0.0.beta3

- Source Map fixes [#255] [#367]
- Performance improvements

## 4.0.0.beta2

- Fix load_paths on Sass processors [#223]


## 4.0.0.beta1

- Initial release of Sprockets 4

Please upgrade to the latest Sprockets 3 version before upgrading to Sprockets 4. Check the 3.x branch for previous changes https://github.com/rails/sprockets/blob/3.x/CHANGELOG.md.

