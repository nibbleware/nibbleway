# C4 Model Level 1: System Context Diagram

In Nibbleway, the **System Context Diagram** is the highest level of your architecture. It allows the Mobile Architect to define the boundaries of the system and its relationships with external vendors and actors.

## Step 1: Define the Core System
Every blueprint starts with a `system` block. This is the entity you are building.

```yaml
version: "1.0"
system:
  name: "Mobile Banking App"
  description: "Allows customers to manage their finances and pay bills."
```

## Step 2: Define External Systems (Vendors)
At the Context level, you represent vendors as `containers` with a `type: "Vendor Service"`. This keeps your design "System of Record" compliant.

```yaml
containers:
  - id: "notification-vendor"
    name: "Push Notification Service"
    type: "Vendor Service"
    category: "Communication"
    vendor: "Amazon SNS"
    technology: "AWS SDK"

  - id: "payment-gateway"
    name: "Payment Processor"
    type: "Vendor Service"
    category: "Finance"
    vendor: "Stripe"
    technology: "Stripe API"
```

## Step 3: Define Actors
Actors are the people or agents interacting with the system.

```yaml
  - id: "customer"
    name: "Retail Customer"
    type: "Actor"
    technology: "Mobile User"
```

## Step 4: Establish Relationships
Use the `relationships` block to define how these entities interact. This is where you document the "Why" and "How" of your architecture.

```yaml
relationships:
  - source: "customer"
    destination: "Mobile Banking App"
    description: "Uses to check balance"
    protocol: "HTTPS"

  - source: "Mobile Banking App"
    destination: "notification-vendor"
    description: "Sends transaction alerts"
    protocol: "AWS SDK"
```

## Step 5: Visualize in Nibbleway Studio
Open this YAML in the **Nibbleway Studio**. The cinematic visualizer will render:
1. **The System** as the center of the mesh.
2. **Vendors** with `building.2.fill` icons (Signaling external dependencies).
3. **Data Packets** flowing between the System and the Vendors to represent API traffic.

> [!TIP]
> Use this level to verify **Vendor Lock-in** and **Security Compliance** before diving into container-level implementation.
