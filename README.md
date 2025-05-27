## Ligolo setup commands
I love ligolo and love using it. This small bash script helps me with running the initial setup for adding a new tuntap device on my OS.
It is easy to use and had to share it for me not to lose it again because I am lazy running these commands everytime I want to use ligolo.
It is straight forward and really easy to use. Pluss once you are done, you can delete the interface and the route if you want. While quitting `ligolo-proxy` you are not quitting the script. So you can always come back to it in case you want to add more routes, delete routes, add more interfaces, delete interfaces, look at the `ifconfig` of the interfaces, start the proxy, quit the proxy, verify the `ligolo` interface, and quit the script.


The script will ask you to choose an option and then it will do the job for you. But if you are having issues. You can contact me on [Twitter/X](https://x.com/1ntell0) or [Discord](https://discordapp.com/users/1098316374125854721) and I will be there to help. If you want to improve this script, feel free to open an issue or a pull request.

> [!WARNING] 
> This was done for educational purposes only. I am not responsible for any damage or loss of data that might happen if you are using this script, which I doubt will ever happen. Use it at your own risk. The script is self-explanatory and easy to use. If you have any questions, feel free to open an issue or a pull request. Or look at the write up [here](https://retr0-1ntell0.github.io/posts/ligolo-setup/).

Hope it helps someone who is also tired of those commands or too much in a rush of typing those commands. 
Planning on adding functionalities as I go because `ligolo-ng` is such a powerfull tool and makes a lot of things easier regarding pivoting.

Keep hacking and enjoy 😄

A full write up of this script can be found [here](https://retr0-1ntell0.github.io/posts/ligolo-setup/).

## Installation
1. Clone this repository or download the script named `ligolo_setup.sh`
2. Don't forget to make it executable
   ```bash
   chmod +x ligolo_setup.sh
   ```
3. Download the linux binary for `ligolo-proxy` from [here](https://github.com/nicocha30/ligolo-ng/releases)
4. Change the name of the binary to `ligolo-proxy` and move it to `/usr/bin/` or anywhere else you want as long it's the PATH of executable binaries.
5. Run the script   
   ```bash
   bash ligolo_setup.sh
   ```
   or 
   ```bash
   ./ligolo_setup.sh
   ```
   Who cares ? It is a bash script.
6. Enjoy 😄


## Improvements
@TODO
This is not its final form, it can always get better.
* [x] Add a way to delete ligolo routes.
* [x] Add a verification/confirmation of the route input.
* [x] Do not start the `ligolo-proxy` without a new route on the interface.
* [x] Add a way to add a new route to the existing interface.
* [x] Add a way to add a new tuntap interface.
* [x] Add a way to delete a route from the existing interface.
* [x] Make a GIF Memo
* [ ] If anything comes up, or any improvement or suggestion in the future.

At this point, I am not sure if I will continue to improve this script.
I am open to suggestions and improvements. Feel free to open an issue or a pull request.
