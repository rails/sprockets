Get upgrade notes from Sprockets 3.x to 4.x at https://github.com/rails/sprockets/blob/master/UPGRADING.md

## Master

- Minimum Ruby version now 2.2 to support refinements, required keyword args, and symbol GC.

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

