##' Given latitude and longitude coordinates, extract site data from NARR file
##'
##' @name extract.nc
##' @title extract.nc
##' @param in.path location on disk where inputs are stored
##' @param in.prefix prefix of input files
##' @param outfolder location on disk where outputs will be stored
##' @param start_date the start date of the data to be permuted (will only use the year part of the date)
##' @param end_date the end date of the data to be permuted (will only use the year part of the date)
##' @param slat the latitude of the site
##' @param slon the longitude of the site
##' @param overwrite should existing files be overwritten
##' @param verbose should ouput of function be extra verbose
##' @export
##' @author Betsy Cowdery
extract.nc <- function(in.path, in.prefix, outfolder, start_date, end_date, slat, slon,
                       overwrite = FALSE, verbose = FALSE, ...) {
  
  library(PEcAn.utils)
  
  in.path   <- as.character(in.path)
  in.prefix <- as.character(in.prefix)
  outfolder <- as.character(outfolder)
  slat      <- eval(parse(text = slat))
  slon      <- eval(parse(text = slon))
  
  if (!file.exists(outfolder)) {
    dir.create(outfolder)
  }
  
  # Find closest coordinates to site
  close <- closest_xy(slat, slon, in.path, in.prefix)
  x <- close$x
  y <- close$y
  
  start_year <- lubridate::year(start_date)
  end_year   <- lubridate::year(end_date)
  rows       <- end_year - start_year + 1
  results    <- data.frame(file = character(rows), 
                           host = character(rows), 
                           mimetype = character(rows), 
                           formatname = character(rows), 
                           startdate = character(rows), 
                           enddate = character(rows), 
                           dbfile.name = in.prefix, 
                           stringsAsFactors = FALSE)
  
  for (year in start_year:end_year) {
    infile <- file.path(in.path, paste(in.prefix, year, "nc", sep = "."))
    outfile <- file.path(outfolder, paste(in.prefix, year, "nc", sep = "."))
    
    # create array with results
    row <- year - start_year + 1
    results$file[row]       <- outfile
    results$host[row]       <- fqdn()
    results$startdate[row]  <- paste0(year, "-01-01 00:00:00")
    results$enddate[row]    <- paste0(year, "-12-31 23:59:59")
    results$mimetype[row]   <- "application/x-netcdf"
    results$formatname[row] <- "CF"
    
    if (file.exists(outfile) && !overwrite) {
      logger.debug("File '", outfile, "' already exists, skipping to next file.")
      next
    }
    
    if (verbose) {
      print(paste(c("ncks", list("-d", 
                                 paste0("x,", x, ",", x), "-d", 
                                 paste0("y,", y, ",", y), 
                                 infile, outfile)), collapse = " "))
    }
    system2("ncks", list("-d", paste0("x,", x, ",", x), "-d", 
                         paste0("y,", y, ",", y), infile, outfile))
    
    ## Hack to ensure lat and lon are consistant
    nc <- ncdf4::nc_open(outfile, write = TRUE)
    ncdf4::ncvar_put(nc, "latitude", vals = slat)
    ncdf4::ncvar_put(nc, "longitude", vals = slon)
    ncdf4::nc_close(nc)
  }
  return(invisible(results))
} # extract.nc
