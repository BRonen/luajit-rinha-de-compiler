# this is a script that runs creates a container with rust to compile arbitrary .rinha sources to ast json on tests folder
# > need to run "cargo install rinha"

docker run -it -v $(pwd)/tests:/home rust:1.70 bash
