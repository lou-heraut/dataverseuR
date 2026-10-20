# Copyright 2025 Louis Héraut (louis.heraut@inrae.fr)*1
#
# *1   INRAE, France
#
# This file is part of dataverseuR R package.
#
# dataverseuR R package is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# dataverseuR R package is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dataverseuR R package.
# If not, see <https://www.gnu.org/licenses/>.


# Driver script of the package: choose the actions in to_do, then run it
# from the root of the package. One block per action; the blocks share the
# variables set below, so that a dataset created by one block can be worked
# on by the next ones in the same run.

devtools::load_all(".")

# The demo instance by default. Switch to .env-entrepot only to act on the
# production repository.
dotenv::load_dot_env(file=".env-demo")
# dotenv::load_dot_env(file=".env-entrepot")


to_do = c(
    # "search_datasets"
    # "create_dataset"
    # "get_metadata"
    # "modify_dataset"
    # "add_files"
    # "list_files"
    # "rename_file"
    # "download_files"
    # "generate_README"
    # "delete_files"
    # "publish_dataset"
    # "get_metrics"
    # "move_dataset"
    # "delete_dataset"
)


# The collection to work in, the dataset to work on (set by create_dataset
# when it runs) and the local working directory, ignored by git.
dataverse = "espacegenerique"
dataset_DOI = ""
work_dir = file.path("dev", "tmp")
metadata_yml_path = file.path(work_dir, "metadata.yml")
dir.create(work_dir, showWarnings=FALSE)


if ("search_datasets" %in% to_do) {
    datasets = search_datasets(query='title:"test"',
                               dataverse=dataverse,
                               n_search=100)
    print(datasets)
}


if ("create_dataset" %in% to_do) {
    # Starts from the metadata template of the package, kept if it already
    # exists so that it can be filled in by hand.
    initialise_metadata(metadata_yml_path)
    metadata_json_path = generate_metadata_json(metadata_yml_path,
                                                overwrite=TRUE)
    dataset_DOI = create_datasets(dataverse, metadata_json_path)
}


if ("get_metadata" %in% to_do) {
    # The metadata of the dataset as JSON, then as a YAML file to edit before
    # modify_dataset.
    metadata_json_path = file.path(work_dir, "metadata.json")
    get_datasets_metadata(dataset_DOI, metadata_json_path, overwrite=TRUE)
    convert_metadata_to_yml(metadata_json_path, overwrite=TRUE)
}


if ("modify_dataset" %in% to_do) {
    metadata_json_path = generate_metadata_json(metadata_yml_path,
                                                overwrite=TRUE)
    modify_datasets(dataverse, dataset_DOI, metadata_json_path)
}


if ("add_files" %in% to_do) {
    # A small table and a text file, written for the example.
    table_path = file.path(work_dir, "flow.csv")
    write.csv(data.frame(date=c("2020-01-01", "2020-01-02"),
                         flow=c("1.5", "2.1")),
              table_path, row.names=FALSE)
    notes_path = file.path(work_dir, "notes.txt")
    writeLines("Notes on the example dataset.", notes_path)
    add_datasets_files(dataset_DOI, c(table_path, notes_path))
}


if ("list_files" %in% to_do) {
    files = list_datasets_files(dataset_DOI)
    print(files[c("filename", "id", "file_DOI", "filesize")])
}


if ("rename_file" %in% to_do) {
    # The files of a draft have no DOI yet: they are named by their id.
    files = list_datasets_files(dataset_DOI)
    id = files$id[files$filename == "notes.txt"]
    rename_datasets_files(id, "notes_renamed.txt", is_DOI_ID=TRUE)
}


if ("download_files" %in% to_do) {
    # Into one directory per dataset, in work_dir.
    download_datasets_files(dataset_DOI, work_dir, overwrite=TRUE)
}


if ("generate_README" %in% to_do) {
    # From the downloaded files: the tables are converted to CSV, then the
    # README describes them.
    clean_datasets_files(dataset_DOI, work_dir, overwrite=TRUE)
    create_datasets_README(dataset_DOI, work_dir, overwrite=TRUE)
}


if ("delete_files" %in% to_do) {
    delete_all_datasets_files(dataset_DOI)
}


if ("publish_dataset" %in% to_do) {
    publish_datasets(dataset_DOI, type="major")
}


if ("get_metrics" %in% to_do) {
    print(get_datasets_citation(dataset_DOI))
    print(get_datasets_metrics(dataset_DOI))
    print(get_datasets_size(dataset_DOI))
}


if ("move_dataset" %in% to_do) {
    # Allowed to collection administrators only.
    move_datasets(dataset_DOI, target_dataverse="target-collection")
}


if ("delete_dataset" %in% to_do) {
    # A draft only: a published dataset cannot be deleted.
    delete_datasets(dataset_DOI)
}
