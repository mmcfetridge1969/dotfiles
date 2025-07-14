# dotfiles
export GITHUB_USERNAME=mmcfetridge1969

{Public repo}
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME

{Private Repo}
chezmoi init --apply git@github.com:$GITHUB_USERNAME/dotfiles.git
