#!/bin/sh

#Can't seem to get this to work for all of the CSS, so just a few below

echo "

css/tabulator.min.css
css/Chart.min.css
css/material.css
css/materialdesignicons.min.css
css/leaflet.css
" | xargs cat | npx uglifycss > css/bundle-css.min.css
