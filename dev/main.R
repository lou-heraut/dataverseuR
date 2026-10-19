# Copyright 2025 Louis Héraut (louis.heraut@inrae.fr)*1
#
# *1   INRAE, France
#
# This file is part of dataverseur R package.
#
# dataverseur R package is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# dataverseur R package is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dataverseur R package.
# If not, see <https://www.gnu.org/licenses/>.


devtools::load_all(".")

dotenv::load_dot_env(file=".env-entrepot")
# dotenv::load_dot_env(file=".env-demo")



to_do = c(
    # "get_metadata"
    # "search_datasets"
    # "create_dataset"
    # "modify_dataset"
    # "add_files"
    # "delete_files"
    # "delete_dataset"
    # "publish_dataset"
    # "get_metrics"
    "generate_README"
)


if ("move_dataset" %in% to_do) {
    dataset_DOI = "doi:10.57745/XFO4GY"
    dataset_ID = convert_DOI_to_ID(dataset_DOI)
    move_datasets(dataset_DOI,
                  target_dataverse="riverly")
}


if ("get_metadata" %in% to_do) {
    dataset_DOI = "doi:10.57745/2YPNZ7"
    metadata_json_path = "metadata.json"
    get_datasets_metadata(dataset_DOI,
                          metadata_json_path,
                          overwrite=TRUE)
    convert_metadata_to_yml(metadata_json_path, overwrite=TRUE)

    # stop()
    # mpath_json = metadata_json_path
    # mpath_yml = "metadata.yml"
    # generate_metadata_json("metadata.yml", overwrite=TRUE)
}


if ("search_datasets" %in% to_do) {

    
    query = 'authorName:"Vidal, Jean-Philippe"'
    publication_status = "RELEASED"
    type = "dataset"
    dataverse = ""
    n_search = 1000
    
    datasets =
        search_datasets(query=query,
                        publication_status=publication_status,
                        type=type,
                        dataverse=dataverse,
                        n_search=n_search)
    datasets = dplyr::distinct(datasets, dataset_DOI,
                               .keep_all=TRUE)
}



if ("create_dataset" %in% to_do) {
    # initialise_metadata_old()
    # source("dev/old/metadata_template.R")
    # res = generate_metadata_old(dev=TRUE)
    generate_metadata_json("metadata.yml")
    dataset_DOI = create_datasets(dataverse="explore2",
                                  metadata_path=res$metadata_path)
}


if ("modify_dataset" %in% to_do) {
    initialise_metadata()
    source("dataset_template.R")
    META$title = gsub("XXX", "Rhône", META$title)
    res = generate_metadata()
    dataset_DOI = modify_dataset_metadata(dataverse="explore2",
                                          dataset_DOI=dataset_DOI,
                                          metadata_path=res$metadata_path)
}

if ("add_files" %in% to_do) {
    add_dataset_files(dataset_DOI=dataset_DOI,
                      paths="LICENSE")
}

if ("delete_files" %in% to_do) {
    delete_dataset_files(dataset_DOI=dataset_DOI)
}

# if ("delete_dataset" %in% to_do) {
#     delete_dataset(dataset_DOI=dataset_DOI)
# }


if ("publish_dataset" %in% to_do) {
    publish_dataset(dataset_DOI, type="major")
}



# datasets_DOI = get_DOI_from_datasets_search(datasets_search)
# dataset_DOI = datasets_DOI[1]
# metadata = get_dataset_metadata(dataset_DOI=dataset_DOI)


# json = jsonlite::toJSON(metadata,
#                  pretty=TRUE,
#                  auto_unbox=TRUE)
# write(json, "tmp.json")

# convert_metadata(metadata)


# flatten_tibble = function (tbl, delimiter="; ") {
#     tbl = dplyr::mutate(tbl,
#                         across(everything(),
#                                ~ ifelse(
#     purrr::map_lgl(.x, is.list),
#     purrr::map_chr(.x, ~paste(unlist(.x),
#                               collapse=delimiter)),
#     .x)))
#     return (tbl)
# }



if ("get_metrics" %in% to_do) {
    # datasets_DOI = get_DOI_from_datasets_search(datasets_search)
    datasets_metrics = get_datasets_metrics(datasets_info$dataset_DOI)
    datasets_info = dplyr::full_join(datasets_info, datasets_metrics,
                                     by="dataset_DOI")

    datasets_size = get_datasets_size(datasets_info$dataset_DOI)
    datasets_info = dplyr::full_join(datasets_info, datasets_size,
                                     by="dataset_DOI")
    
    ASHE::write_tibble(datasets_info,
                       path="datasets_info.csv")
}


if ("generate_README" %in% to_do) {
    
    dataset_DOI =c("doi:10.57745/VOYD57")
    dirpath = file.path("dev", "dataverse_data_etienne")


devtools::load_all("/home/lheraut/Documents/INRAE/projects/ASHE_project/ASHE")
    stop()

    download_datasets_files(dataset_DOI, dirpath)
    clean_datasets_files(dataset_DOI, dirpath, overwrite=TRUE)
    create_datasets_README(dataset_DOI, dirpath,
                           file_pattern="*.csv",
                           overwrite=TRUE)
}
