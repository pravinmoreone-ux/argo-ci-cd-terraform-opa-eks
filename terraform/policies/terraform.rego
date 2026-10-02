package terraform

deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_eks_node_group"

    some instance_type in resource.change.after.instance_types

    not instance_type in {"t3.small", "t3.medium"}

    msg := sprintf(
        "EKS node group %s uses prohibited instance type: %s",
        [resource.name, instance_type]
    )
}

deny contains msg if {
    some resource in input.resource_changes
    resource.change.after.tags.Environment == null

    msg := sprintf(
        "Resource %s is missing the required Environment tag",
        [resource.address]
    )
}

deny contains msg if {
    some resource in input.resource_changes
    resource.change.after.tags.Project == null

    msg := sprintf(
        "Resource %s is missing the required Project tag",
        [resource.address]
    )
}
