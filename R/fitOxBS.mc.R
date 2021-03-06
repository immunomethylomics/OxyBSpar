#' fitOxBS.mc
#' @description
#' fitOxBS.mc function 5-hmC calculation from an oxybisulfite experiment using
#' parallel workers
#' @import minfi
#' @import OxyBS
#' @import foreach
#' @import doParallel
#' @examples
#' # Step 1: Use the OxyBS example
#' data(OxyBSSampleData)
#' nSpecimens <- 30
#' nCpGs <- 30
#' # Calculate Total Signals
#' signalBS <- exampleMethBS+exampleUnmethBS
#' signalOxBS <- exampleMethOxBS+exampleUnmethOxBS
#' # Calculate Beta Values
#' betaBS <- exampleMethBS/signalBS
#' betaOxBS <- exampleMethOxBS/signalOxBS
#' #Serial
#' MethOxy <- array(NA,dim=c(nCpGs,nSpecimens,3))
#' dimnames(MethOxy) <- list(rownames(exampleMethBS)[1:nCpGs],
#' colnames(exampleMethBS)[1:nSpecimens],
#' c("C","5mC","5hmC"))
#' # Process results (one array at a time)
#' system.time(for(i in 1:nSpecimens){
#' MethOxy[,i,] <- fitOxBS(betaBS[,i],betaOxBS[,i],signalBS[,i],signalOxBS[,i])
#' })
#' #Serial solution
#' system.time(MethOxy.serial <- fitOxBS.mc(betaBS,betaOxBS,
#' signalBS,signalOxBS, nCores=1))
#' identical(MethOxy, MethOxy.serial)
#' #Parallel solution
#' system.time(MethOxy.parallel <- fitOxBS.mc(betaBS,betaOxBS,
#' signalBS,signalOxBS, nCores=2))
#' identical(MethOxy, MethOxy.parallel)
#' @references EA Houseman, et al. (2016). \emph{OxyBS: estimation of
#' 5-methylcytosine and 5-hydroxymethylcytosine from tandem-treated oxidative
#' bisulfite and bisulfite DNA}. Bioinformatics. 2016 Aug 15;32(16):2505-7.
#' doi: 10.1093/bioinformatics/btw158.
#' @param
#' betaBS	beta value from conventional bisulfite conversion.
#' @param
#' betaOxBS	beta value from oxy-bisulfite conversion
#' @param
#' signalBS	total signal from conventional bisulfite conversion
#' @param
#' signalOxBS	total signal from oxy-bisulfite conversion
#' @param
#' eps	small positive value representing numerical zero
#' @param
#' nCores number of Cores used for the analysis. You can use detectCores() too.
#'@return
#' This function will return an array containing (C,5mC,5hmC), per CpG and per
#' subject. Uses maximum likelihood to estimate one by one CpG per specimen.
#' @export
fitOxBS.mc<-function (betaBS, betaOxBS, signalBS, signalOxBS, eps = 1e-05,
                      nCores=2) {
    if(nCores==1){
        nSpecimens<-dim(betaBS)[2]
        nCpGs<-dim(betaBS)[1]
        out1 <- foreach (j=1:nCpGs) %:%
            foreach(i=1:nSpecimens) %do%{
                fitOneOxBS(betaBS[j,i], betaOxBS[j,i], signalBS[j,i],
                           signalOxBS[j,i], eps = eps)
            }
        out <- array(data=NA, dim = c(nCpGs,nSpecimens,3), dimnames = list(
            rownames(betaBS), colnames(betaBS), c("C","5mC","5hmC")))
        for (k in 1:nSpecimens){
            out[k,,]<-matrix(unlist(out1[[k]]), ncol=3, byrow = TRUE)
        }
        out
    } else{
        c1 <- makeCluster(nCores)
        registerDoParallel(c1)
        nSpecimens<-dim(betaBS)[2]
        nCpGs<-dim(betaBS)[1]
        out1 <- foreach (j=1:nCpGs, .packages = "OxyBS") %:%
            foreach(i=1:nSpecimens, .packages = "OxyBS") %dopar%{
                fitOneOxBS(betaBS[j,i], betaOxBS[j,i], signalBS[j,i],
                           signalOxBS[j,i], eps = eps)
            }
        stopCluster(c1)
        out <- array(data=NA, dim = c(nCpGs,nSpecimens,3), dimnames = list(
            rownames(betaBS), colnames(betaBS), c("C","5mC","5hmC")))
        for (k in 1:nSpecimens){
            out[k,,]<-matrix(unlist(out1[[k]]), ncol=3, byrow = TRUE)
        }
        out
    }

}
