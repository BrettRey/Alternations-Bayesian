
# 1. Load Data for Scaling Info
clauses <- readRDS("data/processed/oanc-clauses.rds")

# Calculate scaling params (LINEAR SCALING as per 05_fit_baseline.R)
mean_len <- mean(clauses$clause_len_tokens, na.rm = TRUE)
sd_len <- sd(clauses$clause_len_tokens, na.rm = TRUE)

mean_dist <- mean(clauses$distance_tokens, na.rm = TRUE)
sd_dist <- sd(clauses$distance_tokens, na.rm = TRUE)

# 2. Load Model Summary
params <- read.csv("results/baseline_param_summary.csv", stringsAsFactors = FALSE)

get_param <- function(name) {
  val <- params$mean[params$variable == name]
  if (length(val) == 0) stop("Parameter not found: ", name)
  val
}

beta_len <- get_param("beta_len")
beta_dist <- get_param("beta_dist")

alpha_reg_spoken <- get_param("alpha_reg[1]")
alpha_reg_acad <- get_param("alpha_reg[3]")

# 3. Create Prediction Grids
# Function to compute prob
logit2prob <- function(l) 1 / (1 + exp(-l))

# -- Grid for Length --
len_seq <- seq(2, 40, length.out = 100)
len_scaled <- (len_seq - mean_len) / sd_len # Linear scaling
# Hold distance at mean (0 in scaled units)
pred_len_spoken <- logit2prob(alpha_reg_spoken + beta_len * len_scaled)
pred_len_acad <- logit2prob(alpha_reg_acad + beta_len * len_scaled)

# -- Grid for Distance --
dist_seq <- seq(0, 15, length.out = 100)
dist_scaled <- (dist_seq - mean_dist) / sd_dist
# Hold length at mean (0 in scaled units)
pred_dist_spoken <- logit2prob(alpha_reg_spoken + beta_dist * dist_scaled)
pred_dist_acad <- logit2prob(alpha_reg_acad + beta_dist * dist_scaled)

# 4. Plot (Combined)
png("results/figures/effects_combined.png", width = 2000, height = 900, res = 150)
par(mfrow = c(1, 2), mar = c(5, 4, 3, 1) + 0.1)

# Common ylim
ylim_range <- c(0, 0.6)

# Panel A: Clause Length
plot(len_seq, pred_len_acad, type = "n", ylim = ylim_range,
     xlab = "Clause Length (words)", ylab = "Predicted Probability of 'that'",
     main = "A. Effect of Clause Length", cex.main = 1.2, cex.lab = 1.1, las = 1)
grid(col = "gray90", lty = "dotted")
lines(len_seq, pred_len_spoken, col = "#E7298A", lwd = 3) # Spoken
lines(len_seq, pred_len_acad, col = "#1B9E77", lwd = 3)   # Academic
text(35, pred_len_acad[length(len_seq)] + 0.02, expression(paste("Longer favour ", italic("that"))), 
     pos = 2, col = "gray40", cex = 0.9)
legend("topleft", legend = c("Academic", "Spoken"),
       col = c("#1B9E77", "#E7298A"), lwd = 3, bty = "n", cex = 1.1)

# Panel B: Distance
plot(dist_seq, pred_dist_acad, type = "n", ylim = ylim_range,
     xlab = "Distance (words)", ylab = "",
     main = "B. Effect of Distance", cex.main = 1.2, cex.lab = 1.1, las = 1)
grid(col = "gray90", lty = "dotted")
lines(dist_seq, pred_dist_spoken, col = "#E7298A", lwd = 3)
lines(dist_seq, pred_dist_acad, col = "#1B9E77", lwd = 3)
text(14, pred_dist_acad[length(dist_seq)] + 0.02, expression(paste("Distance disfavours ", italic("that"))), 
     pos = 2, col = "gray40", cex = 0.9)

dev.off()
