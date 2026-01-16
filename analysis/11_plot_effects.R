
# 1. Load Data for Scaling Info
clauses <- readRDS("data/processed/oanc-clauses.rds")

# Calculate scaling params
log_len <- log(clauses$clause_len)
mean_log_len <- mean(log_len)
sd_log_len <- sd(log_len)

# 2. Load Model Summary
params <- read.csv("results/baseline_param_summary.csv", stringsAsFactors = FALSE)

get_param <- function(name) {
  val <- params$mean[params$variable == name]
  # Exact match logic
  if (length(val) == 0) stop("Parameter not found: ", name)
  val
}

# No global alpha, model uses register intercepts directly
beta_len <- get_param("beta_len")

# Register intercepts
alpha_reg_spoken <- get_param("alpha_reg[1]")
alpha_reg_acad <- get_param("alpha_reg[3]")

# 3. Create Prediction Grid
# We want to plot Clause Length (words) from e.g. 2 to 30.
len_seq <- seq(2, 40, length.out = 100)
len_scaled <- (log(len_seq) - mean_log_len) / sd_log_len

# Function to compute prob
logit2prob <- function(l) 1 / (1 + exp(-l))

# Prediction for Spoken (Intercept + slope)
pred_spoken <- logit2prob(alpha_reg_spoken + beta_len * len_scaled)

# Prediction for Academic
pred_acad <- logit2prob(alpha_reg_acad + beta_len * len_scaled)

# 4. Plot
png("results/figures/effects_length.png", width = 1200, height = 900, res = 150)

# Setup empty plot
# Find range for ylim (Spoken starts low ~6%, Acad starts higher)
ylim_range <- c(0, max(pred_acad) * 1.1)
ylim_range <- c(0, 0.6) # Standardize to 60% for readability

plot(len_seq, pred_acad, type = "n",
     ylim = ylim_range,
     xlab = "Clause Length (words)",
     ylab = "Predicted Probability of 'that'",
     main = "Effect of Clause Length on that-use",
     cex.main = 1.2, cex.lab = 1.1, las = 1)

# Add grid
grid(nx = NULL, ny = NULL, col = "gray90", lty = "dotted")

# Add lines
lines(len_seq, pred_spoken, col = "#E7298A", lwd = 3) # Pink/Purple
lines(len_seq, pred_acad, col = "#1B9E77", lwd = 3)   # Green

# Add Legend
legend("topleft", legend = c("Academic", "Spoken"),
       col = c("#1B9E77", "#E7298A"), lwd = 3, bty = "n", cex = 1.1)

# Add text annotation
text(35, pred_acad[length(len_seq)] + 0.02, "Longer clauses\nfavor 'that'", pos = 2, col = "gray40", cex = 0.9)

dev.off()
