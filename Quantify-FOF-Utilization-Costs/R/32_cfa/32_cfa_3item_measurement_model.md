# 32 CFA 3-item Measurement Model

## Manuscript-ready model description

The core locomotor capacity model is a one-factor confirmatory factor analysis
with three reflective indicators:

`Capacity =~ gait + chair + balance`

Interpretation of indicators:

- `gait`: gait speed from the timed 10-meter walk test
- `chair`: chair rise performance from the five-times chair stand test
- `balance`: standing balance from single-leg stance performance

## Simple figure version

Locomotor Capacity -> gait speed  
Locomotor Capacity -> chair rise  
Locomotor Capacity -> balance

## Mermaid diagram

```mermaid
flowchart TB
    LC[Locomotor Capacity\nlatent factor eta]
    G[gait speed\n10 m walk]
    C[chair rise\n5x chair stand]
    B[balance\nsingle-leg stance]
    E1[epsilon1]
    E2[epsilon2]
    E3[epsilon3]

    LC -->|lambda1| G
    LC -->|lambda2| C
    LC -->|lambda3| B
    E1 --> G
    E2 --> C
    E3 --> B
```

## Suggested figure caption

Measurement model for the latent locomotor capacity construct. The latent factor
was specified using three reflective indicators: gait speed, chair rise
performance, and standing balance. Estimated factor loadings quantify the
strength of association between each observed indicator and the underlying
locomotor capacity construct.

## Suggested Results sentence

The latent locomotor capacity construct was modeled as a one-factor CFA with
three reflective indicators: gait speed, chair rise performance, and standing
balance.
