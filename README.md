# DESCRIPTION

This is a [Graphite](https://graphite.readthedocs.io/en/stable/) interface to data provided by [The COVID Tracking Project](https://covidtracking.com/).

Handles downloading the latest daily data from [The COVID Tracking Project](https://covidtracking.com/), calculating extra population adjusted statistics, and loading it into [Graphite](https://graphite.readthedocs.io/en/stable/).

# SETUP

	./bin/grafana && ./bin/graphite
	carton install && carton exec -- perl ./bin/load

# SCRIPTS

## bin/load

	carton exec -- perl ./bin/load [--update]

Load daily data from [The COVID Tracking Project](https://covidtracking.com/) into [Graphite](https://graphite.readthedocs.io/en/stable/).

Use the `--update` option to force it to pull down the latest data. Otherwise it will reuse cached data written to the `./data` directory.

