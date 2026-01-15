#!/usr/bin/env Rscript

# Generate basic diagnostic plots from results/ summaries.

results_dir <- "results"
fig_dir <- file.path(results_dir, "figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
ppc_xlim <- c(0, 0.5)
ppc_zoom_width <- 0.03

zoom_xlim <- function(obs, full = ppc_xlim, width = ppc_zoom_width) {
  half <- width / 2
  if (is.na(obs)) return(full)
  low <- obs - half
  high <- obs + half
  if (low < full[1]) {
    low <- full[1]
    high <- min(full[1] + width, full[2])
  }
  if (high > full[2]) {
    high <- full[2]
    low <- max(full[2] - width, full[1])
  }
  c(low, high)
}

# Helper for safe read
safe_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  read.csv(path, stringsAsFactors = FALSE)
}
safe_read_rds <- function(path) {
  if (!file.exists(path)) return(NULL)
  readRDS(path)
}

ppc_overall <- safe_read(file.path(results_dir, "ppc_overall.csv"))
ppc_by_reg <- safe_read(file.path(results_dir, "ppc_by_register.csv"))
oos_ppc_overall <- safe_read(file.path(results_dir, "oos_ppc_overall.csv"))
oos_ppc_by_reg <- safe_read(file.path(results_dir, "oos_ppc_by_register.csv"))
summary_regs <- safe_read(file.path(results_dir, "data_summary_by_register.csv"))
summary_lemmas <- safe_read(file.path(results_dir, "data_summary_top_lemmas.csv"))
ppc_doc <- safe_read_rds(file.path(results_dir, "ppc_doc_rates.rds"))
oos_ppc_doc <- safe_read_rds(file.path(results_dir, "oos_ppc_doc_rates.rds"))

reg_label <- function(reg, oos = FALSE, zoom = FALSE) {
  base_expr <- switch(
    reg,
    "written_1" = "plain(written)[1]",
    "written_2" = "plain(written)[2]",
    reg
  )
  if (reg %in% c("written_1", "written_2")) {
    label_expr <- base_expr
    if (zoom) {
      label_expr <- paste0("paste(", base_expr, ", ' (zoom)')")
    }
    if (oos) {
      label_expr <- paste0("paste('OOS ', ", label_expr, ")")
    }
    return(parse(text = label_expr))
  }
  label <- base_expr
  if (oos) label <- paste("OOS", label)
  if (zoom) label <- paste(label, "(zoom)")
  label
}

slugify <- function(x) gsub("[^A-Za-z0-9]+", "_", x)

reg_axis_labels <- function(regs) {
  reg_expr <- vapply(regs, function(r) {
    if (r == "written_1") return("plain(written)[1]")
    if (r == "written_2") return("plain(written)[2]")
    r
  }, character(1))
  parse(text = reg_expr)
}

plot_doc_ppc <- function(obj, prefix, oos = FALSE) {
  if (is.null(obj)) return(invisible(NULL))
  obs <- obj$obs
  pred <- obj$pred
  doc_map <- obj$doc_map
  regs <- unique(obs$register)
  for (reg in regs) {
    doc_idx <- which(doc_map$register == reg)
    if (length(doc_idx) == 0) next
    pred_vals <- as.vector(pred[, doc_idx])
    obs_vals <- obs$obs_rate[obs$register == reg]
    slug <- slugify(reg)
    title <- if (oos) "OOS doc-level PPC" else "Doc-level PPC"
    main <- reg_label(reg, oos = oos)
    png(file.path(fig_dir, paste0(prefix, "_", slug, ".png")), width = 900, height = 600)
    hist(pred_vals, breaks = 40, col = "grey85", freq = FALSE,
         main = title,
         xlab = expression(paste("Document ", italic(that), "-content clause rate")),
         xlim = c(0, 1))
    hist(obs_vals, breaks = 40, col = adjustcolor("firebrick", alpha.f = 0.35),
         freq = FALSE, add = TRUE)
    legend("topright",
           legend = c("Predicted docs", "Observed docs"),
           fill = c("grey85", adjustcolor("firebrick", alpha.f = 0.35)),
           border = c("grey85", adjustcolor("firebrick", alpha.f = 0.35)),
           bty = "n")
    mtext(main, side = 3, line = 0.2, cex = 0.9)
    dev.off()
  }
}

if (!is.null(ppc_overall)) {
  png(file.path(fig_dir, "ppc_overall.png"), width = 1000, height = 700)
  hist(ppc_overall$pred_rate, breaks = 40, col = "grey80",
       main = expression(paste("PPC: overall ", italic(that), "-content clause rate")),
       xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
       xlim = ppc_xlim)
  abline(v = unique(ppc_overall$obs_rate)[1], col = "firebrick", lwd = 2)
  legend("topright", legend = c("Posterior predictive", sprintf("Observed = %.3f", unique(ppc_overall$obs_rate)[1])),
         fill = c("grey80", NA), border = c("grey80", NA),
         lwd = c(NA, 2), col = c(NA, "firebrick"), bty = "n")
  dev.off()

  obs <- unique(ppc_overall$obs_rate)[1]
  png(file.path(fig_dir, "ppc_overall_zoom.png"), width = 1000, height = 700)
  hist(ppc_overall$pred_rate, breaks = 40, col = "grey80",
       main = expression(paste("PPC (zoom): overall ", italic(that), "-content clause rate")),
       xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
       xlim = zoom_xlim(obs))
  abline(v = obs, col = "firebrick", lwd = 2)
  legend("topright", legend = c("Posterior predictive", sprintf("Observed = %.3f", obs)),
         fill = c("grey80", NA), border = c("grey80", NA),
         lwd = c(NA, 2), col = c(NA, "firebrick"), bty = "n")
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
         main = reg_label(reg), xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = ppc_xlim)
    abline(v = unique(subset$obs_rate)[1], col = "firebrick", lwd = 2)
  }
  dev.off()

  png(file.path(fig_dir, "ppc_by_register_zoom.png"), width = 1200, height = 600 + 250 * nrow)
  par(mfrow = c(nrow, ncol), mar = c(4, 4, 3, 1))
  for (reg in regs) {
    subset <- ppc_by_reg[ppc_by_reg$register == reg, ]
    obs <- unique(subset$obs_rate)[1]
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, zoom = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = zoom_xlim(obs))
    abline(v = obs, col = "firebrick", lwd = 2)
  }
  dev.off()

  for (reg in regs) {
    subset <- ppc_by_reg[ppc_by_reg$register == reg, ]
    obs <- unique(subset$obs_rate)[1]
    slug <- slugify(reg)
    png(file.path(fig_dir, paste0("ppc_by_register_", slug, ".png")), width = 900, height = 600)
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = ppc_xlim)
    abline(v = obs, col = "firebrick", lwd = 2)
    dev.off()

    png(file.path(fig_dir, paste0("ppc_by_register_", slug, "_zoom.png")), width = 900, height = 600)
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, zoom = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = zoom_xlim(obs))
    abline(v = obs, col = "firebrick", lwd = 2)
    dev.off()
  }
}

if (!is.null(oos_ppc_overall)) {
  png(file.path(fig_dir, "oos_ppc_overall.png"), width = 1000, height = 700)
  hist(oos_ppc_overall$pred_rate, breaks = 40, col = "grey80",
       main = expression(paste("OOS PPC: overall ", italic(that), "-content clause rate")),
       xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
       xlim = ppc_xlim)
  abline(v = unique(oos_ppc_overall$obs_rate)[1], col = "firebrick", lwd = 2)
  legend("topright", legend = c("Posterior predictive", sprintf("Observed = %.3f", unique(oos_ppc_overall$obs_rate)[1])),
         fill = c("grey80", NA), border = c("grey80", NA),
         lwd = c(NA, 2), col = c(NA, "firebrick"), bty = "n")
  dev.off()

  obs <- unique(oos_ppc_overall$obs_rate)[1]
  png(file.path(fig_dir, "oos_ppc_overall_zoom.png"), width = 1000, height = 700)
  hist(oos_ppc_overall$pred_rate, breaks = 40, col = "grey80",
       main = expression(paste("OOS PPC (zoom): overall ", italic(that), "-content clause rate")),
       xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
       xlim = zoom_xlim(obs))
  abline(v = obs, col = "firebrick", lwd = 2)
  legend("topright", legend = c("Posterior predictive", sprintf("Observed = %.3f", obs)),
         fill = c("grey80", NA), border = c("grey80", NA),
         lwd = c(NA, 2), col = c(NA, "firebrick"), bty = "n")
  dev.off()
}

if (!is.null(oos_ppc_by_reg) && nrow(oos_ppc_by_reg) > 0) {
  regs <- unique(oos_ppc_by_reg$register)
  n <- length(regs)
  ncol <- 2
  nrow <- ceiling(n / ncol)
  png(file.path(fig_dir, "oos_ppc_by_register.png"), width = 1200, height = 600 + 250 * nrow)
  par(mfrow = c(nrow, ncol), mar = c(4, 4, 3, 1))
  for (reg in regs) {
    subset <- oos_ppc_by_reg[oos_ppc_by_reg$register == reg, ]
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, oos = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = ppc_xlim)
    abline(v = unique(subset$obs_rate)[1], col = "firebrick", lwd = 2)
  }
  dev.off()

  png(file.path(fig_dir, "oos_ppc_by_register_zoom.png"), width = 1200, height = 600 + 250 * nrow)
  par(mfrow = c(nrow, ncol), mar = c(4, 4, 3, 1))
  for (reg in regs) {
    subset <- oos_ppc_by_reg[oos_ppc_by_reg$register == reg, ]
    obs <- unique(subset$obs_rate)[1]
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, oos = TRUE, zoom = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = zoom_xlim(obs))
    abline(v = obs, col = "firebrick", lwd = 2)
  }
  dev.off()

  for (reg in regs) {
    subset <- oos_ppc_by_reg[oos_ppc_by_reg$register == reg, ]
    obs <- unique(subset$obs_rate)[1]
    slug <- slugify(reg)
    png(file.path(fig_dir, paste0("oos_ppc_by_register_", slug, ".png")), width = 900, height = 600)
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, oos = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = ppc_xlim)
    abline(v = obs, col = "firebrick", lwd = 2)
    dev.off()

    png(file.path(fig_dir, paste0("oos_ppc_by_register_", slug, "_zoom.png")), width = 900, height = 600)
    hist(subset$pred_rate, breaks = 30, col = "grey85",
         main = reg_label(reg, oos = TRUE, zoom = TRUE),
         xlab = expression(paste("Predicted ", italic(that), "-content clause rate")),
         xlim = zoom_xlim(obs))
    abline(v = obs, col = "firebrick", lwd = 2)
    dev.off()
  }
}

if (!is.null(summary_regs) && nrow(summary_regs) > 0) {
  top_regs <- summary_regs[1:min(12, nrow(summary_regs)), ]
  png(file.path(fig_dir, "that_rate_by_register.png"), width = 1100, height = 700)
  barplot(top_regs$that_rate, names.arg = reg_axis_labels(top_regs$register), las = 2,
          col = "grey75", ylab = expression(paste(italic(that), "-content clause rate")),
          main = expression(paste(italic(that), "-content clause rate by register (top 12 by N)")))
  dev.off()
}

if (!is.null(summary_lemmas) && nrow(summary_lemmas) > 0) {
  top_lemmas <- summary_lemmas[1:min(15, nrow(summary_lemmas)), ]
  png(file.path(fig_dir, "that_rate_top_lemmas.png"), width = 1100, height = 700)
  barplot(top_lemmas$that_rate, names.arg = top_lemmas$head_lemma, las = 2,
          col = "grey75", ylab = expression(paste(italic(that), "-content clause rate")),
          main = expression(paste(italic(that), "-content clause rate by head lemma (top 15 by N)")))
  dev.off()
}

plot_doc_ppc(ppc_doc, "ppc_doc_by_register", oos = FALSE)
plot_doc_ppc(oos_ppc_doc, "oos_ppc_doc_by_register", oos = TRUE)

message("Plots written to results/figures/.")
