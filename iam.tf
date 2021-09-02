resource "aws_iam_role" "control_plane" {
    name = format("%s-cp", local.name)
    tags = merge(local.default-tags, var.tags)
    assume_role_policy = jsonencode({
        Version : "2012-10-17",
        Statement : [
        {
            Effect : "Allow",
            Principal : {
            Service : "eks.amazonaws.com"
            },
            Action : "sts:AssumeRole"
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.control_plane.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role = aws_iam_role.control_plane.name
}

