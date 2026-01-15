#!/usr/bin/env Rscript

# Generate basic diagnostic plots from results/ summaries.

results_dir <- "results"
fig_dir <- file.path(results_dir, "figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# Helper for safe read
safe_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  read.csv(path, stringsAsFactors = FALSE)
}

ppc_overall <- safe_read(file.path(results_dir, "ppc_overall.csv"))
ppc_by_reg <- safe_read(file.path(results_dir, "ppc_by_register.csv"))
summary_regs <- safe_read(file.path(results_dir, "data_summary_by_register.csv"))
summary_lemmas <- safe_read(file.path(results_dir, "data_summary_top_lemmas.csv"))

if (!is.null(ppc_overall)) {
  png(file.path(fig_dir, "ppc_overall.png"), width = 1000, height = 700)
  hist(ppc_overall$pred_rate, breaks = 40, col = "grey80",
       main = "PPC: overall overt-that rate",
       xlab = "Predicted overt-that rate")
  abline(v = unique(ppc_overall$obs_rate)[1], col = "firebrick", lwd = 2)
  legend("topright", legend = sprintf("Observed = %.3f", unique(ppc_overall$obs_rate)[1]),
         lwd = 2, col = "firebrick", bty = "n")
  dev.off()
}

if (!is.null(ppc_by_reg) && nrow(ppc_by_reg) > 0) {
  regs <- unique(ppc_by_reg$register)
  n <- length(regs)
  ncol <- 2
  nrow <- ceiling(n / ncol)
  png(file.path(fig_dir, "ppc_by_register.png"), width = 1200, height = 600 + 250 * nrow)
  par(mfrow = c(nrow, ncol), mar = c(4, 4, 3, 1))
  for (reg in regs) {
    subset <- ppc_by_reg[ppc_by_reg$register == reg, ]
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg, xlab = "Predicted overt-that rate")
    abline(v = unique(subset$obs_rate)[1], col = "firebrick", lwd = 2)
  }
  dev.off()
}

if (!is.null(summary_regs) && nrow(summary_regs) > 0) {
  top_regs <- summary_regs[1:min(12, nrow(summary_regs)), ]
  png(file.path(fig_dir, "that_rate_by_register.png"), width = 1100, height = 700)
  barplot(top_regs$that_rate, names.arg = top_regs$register, las = 2,
          col = "grey75", ylab = "Overt-that rate",
          main = "Overt-that rate by register (top 12 by N)")
  dev.off()
}

if (!is.null(summary_lemmas) && nrow(summary_lemmas) > 0) {
  top_lemmas <- summary_lemmas[1:min(15, nrow(summary_lemmas)), ]
  png(file.path(fig_dir, "that_rate_top_lemmas.png"), width = 1100, height = 700)
  barplot(top_lemmas$that_rate, names.arg = top_lemmas$head_lemma, las = 2,
          col = "grey75", ylab = "Overt-that rate",
          main = "Overt-that rate by head lemma (top 15 by N)")
  dev.off()
}

message("Plots written to results/figures/.")
