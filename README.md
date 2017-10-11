[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://choosealicense.com/licenses/mit/)

# ProvisioningVMs
Bash scripts to (ideally) provision a VM for "automated-ish" deployment

## Usage
1. Find the provisioning file you desire (they're each pretty descriptive with version numbers and Linux kernels).
2. Use a wget command in your terminal window similar to this one: 

`wget -O Graylog2-OneNode-Ubuntu1604.sh https://raw.githubusercontent.com/tscibilia/ProvisioningVMs/master/Graylog2-OneNode-Ubuntu1604.sh`

3. Make the bash script you downloaded executable similar to this:

`chmod +x Graylog2-OneNode-Ubuntu1604.sh`

4. Run the bash script by changing to the directory (assumed to be home "~/"), then:

`./Graylog2-OneNode-Ubuntu1604.sh`

## License
_ProvisioningVMs_ is released under the [MIT License](LICENSE).
