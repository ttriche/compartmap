#' @title Estimate A/B compartments
#'
#' @description 
#' \code{getCompartments} returns estimated A/B compartments from ATAC-seq and methylation array data
#'
#' @details 
#' This is a wrapper function to perform A/B compartment inference. Compartmentalizer implements a Stein estimator to shrink per-sample compartment estimates towards a global mean. The expected input for this function can be generated using packages like SeSAMe and ATACseeker.
#'
#' @param obj The object with which to perform compartment inference
#' @param type The type of data that obj represents (e.g. atac or array)
#' @param res Resolution of compartments in base pairs (default is 1e6)
#' @param parallel Should the estimates be done in parallel (default is FALSE)
#' @param chrs Chromosomes to operate on (can be individual chromosomes, a list of chromosomes, or all)
#' @param genome Genome to use (default is hg19)
#' @param targets Specify samples to use as shrinkage targets
#' @param run_examples Whether to run ATAC-seq and 450k example analysis
#' @param ... Other parameters to pass to internal functions
#'
#' @return A p x n matrix (samples as columns and compartments as rows) to pass to embed_compartments
#' 
#' @import gtools 
#' @import parallel
#' @import Homo.sapiens
#' @import minfi
#' @import GenomicRanges
#' 
#' @export
#'
#' @examples
#' 
#' library(GenomicRanges)
#' library(SummarizedExperiment)
#' library(Homo.sapiens)
#' 
#' #ATAC-seq data
#' data(bulkATAC_raw_filtered_chr14, package = "compartmap")
#' atac_compartments <- getCompartments(filtered.data.chr14, type = "atac", parallel = FALSE, chrs = "chr14")
#' \dontrun{
#' #450k data
#' data(meth_array_450k_chr14, package = "compartmap")
#' array_compartments <- getCompartments(array.data.chr14, type = "array", parallel = FALSE, chrs = "chr14")}

getCompartments <- function(obj, type = c("atac", "array"), res = 1e6, parallel = FALSE,
                             chrs = "chr1", genome = "hg19", targets = NULL, run_examples = FALSE, ...) {
  
  # Perform initial check the input data type
  if (type %in% c("atac", "array")) {
    type <- match.arg(type)
  } else {
    stop("Don't know what to do with the supplied type argument. Can be 'atac' or 'array'.")
  }
  
  # Check object class for a given type
  if (type == "atac") {
    if (!is(obj, "RangedSummarizedExperiment")) {
      stop("obj needs to be a RangedSummarizedExperiment object. Can be generated using the ATACseeker package.")
    }
  }
  if (type == "array") {
    if (!is(obj, "GenomicRatioSet")) {
      stop("obj needs to be an GenomicRatioSet object. Can be generated using the sesame package.")
    }
  }
  
  #Pre-check the chromosomes to be analyzed
  if (chrs == "all") {
    allchrs <- TRUE
    chrs <- NULL
    message("Proceeding with all chromosomes...")
  } else {
    allchrs <- FALSE
    message(paste0("Proceeding with chromosome(s): ", paste(shQuote(chrs), collapse = ", ")))
  }
  
  # ATACseq
  # Check whether the input object is a RSE object for ATACseq data
  if (is(obj, "RangedSummarizedExperiment") & type == "atac") {
    if (allchrs == TRUE) {
      compartments <- getATACABsignal(obj = obj, res = res, parallel = parallel, allchrs = allchrs, chr = chrs, targets = targets, ...)
    } else {
      compartments <- getATACABsignal(obj = obj, res = res, parallel = parallel, allchrs = FALSE, chr = chrs, targets = targets, ...)
    }
    return(compartments)
  }
  
  # Methylation array (e.g. 450k or EPIC)
  # Check whether the input object is an GRset object for array data
  if (is(obj, "GenomicRatioSet") & type == "array") {
    if (allchrs == TRUE) {
      compartments <- getArrayABsignal(obj = obj, res = res, parallel = parallel, allchrs = allchrs, chr = chrs, targets = targets, ...)
      } else {
      compartments <- getArrayABsignal(obj = obj, res = res, parallel = parallel, allchrs = FALSE, chr = chrs, targets = targets, ...)
      }
    return(compartments)
  }
  
  #Run examples
  if (run_examples) {
    message("Running ATAC-seq example data...")
    data(bulkATAC_raw_filtered_chr14, package = "compartmap")
    atac_compartments <- getCompartments(filtered.data.chr14, type = "atac", parallel = FALSE, chrs = "chr14")
    message("Done!")
    message("Running 450k example data...")
    data(meth_array_450k_chr14, package = "compartmap")
    array_compartments <- getCompartments(array.data.chr14, type = "array", parallel = FALSE, chrs = "chr14")
    message("Done!")
    return(list(atac = atac_compartments, array = array_compartments))
  }
}

#' Example ATAC-seq data for compartmap
#' 
#' This data was generated using the data from the reference via bwa mem
#' and pre-processing the data using the ATACseeker package.
#' 
#' @name filtered.data.chr14
#' @docType data
#' @author Benjamin K Johnson \email{ben.johnson@vai.org}
#' @references \url{https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP082417}
#' @keywords data
#' @usage data(bulkATAC_raw_filtered_chr14, package = "compartmap")
NULL

#' Example Illumina 450k methylation array data for compartmap
#' 
#' This data was generated using the data from the reference via the
#' sesamize function from the SeSAMe package.
#' 
#' @name array.data.chr14
#' @docType data
#' @author Benjamin K Johnson \email{ben.johnson@vai.org}
#' @references \url{https://f1000research.com/articles/5-1281/v3}
#' @keywords data
#' @usage data(meth_array_450k_chr14, package = "compartmap")
NULL
