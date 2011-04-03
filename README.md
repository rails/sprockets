<div style="border: 1px solid #c00; background: #fff; padding: 5px 10px"><strong>This is an in-progress rewrite of Sprockets</strong> to be released as version 2.0. Please see the <a href="https://github.com/sstephenson/sprockets/tree/1.0.x">1.0.x branch</a> for information on the current release.</div>

Sprockets 2
===========

Sprockets 2 is a Rack-based asset packaging system that concatenates
and serves JavaScript, CoffeeScript, CSS, LESS, Sass, and SCSS.

This version is a rewrite of Sprockets that addresses a number of issues
with the original version's design.

* Emphasis on serving, not generating.
* Support for multiple concatenations.
* Support for CSS concatenations.
* Support for CoffeeScript, LESS, Sass and SCSS preprocessing.
* Simplified, header-comment-based dependency declarations.
* Opt-in interpolation with ERB support.
* Serve images and other assets from anywhere in the load path.

More coming soon.
