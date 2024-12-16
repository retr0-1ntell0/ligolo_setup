## Ligolo setup commands
I love ligolo and love using it. This small bash script helps me with running the initial setup for adding a new tuntap device on my OS.
It is easy to use and had to share it for me not to lose it again because I am lazy running these commands everytime I want to use ligolo.
It is straight forward and really easy to use. Pluss once you are done, you can delete the interface and the route if you want. While quitting `ligolo-proxy` you are not quitting the script. So you can always come back to it in case you want to add more routes, delete routes, add more interfaces, delete interfaces, look at the `ifconfig` of the interfaces, start the proxy, quit the proxy, verify the `ligolo` interface, and quit the script.

### Requirement
The only requirement so far is to have root access or password to be able to make it work. If you are having issues running the commands you are proably missing `iproute` or `iproute2`, `awk`, `grep`, `xargs` and `nl` packages depending on your OS. Of course, you need to have `ligolo-ng` installed and the proxy having the name `ligolo-proxy` in your PATH.

On Debian/Ubuntu-based distributions:
```
sudo apt update
sudo apt install iproute2
```
On Red Hat/CentOS/Fedora-based distributions:
```
sudo yum install iproute
```
or (on newer versions of Fedora):
```
sudo dnf install iproute
```
On Arch Linux:
```
sudo pacman -S iproute2
```
or 
```
yay -S iproute2
```
## Usage
Very easy to use, so that you don't have to type these everytime. You can add one or delete one. Your choice.
Once installed, give it executable permissions. Also make sure to have `ligolo-ng` installed and the proxy having the name `ligolo-proxy` in your PATH.
> Here is a link to the `ligolo-ng` [binaries](https://github.com/nicocha30/ligolo-ng/releases)

```bash
chmod +x ligolo-setup.sh
```
Once this step is done we are ready to roll, now just execute it and make a choice:
```bash
./ligolo-setup.sh
```
Here is a screenshot of the script banner:

![alt text](image.png)

Here is a video demo of some use cases:

![Demo](ligolo-setup_demo.GIF)

Music: [Purple Planet Music](https://www.purple-planet.com/tracks/rapid-transit)


The script will ask you to choose an option and then it will do the job for you. But if you are having issues. You can contact me on [Twitter/X](https://x.com/0xretr0__) or [Discord](https://discordapp.com/users/1098316374125854721) and I will be there to help. If you want to improve this script, feel free to open an issue or a pull request.

> P.S: I am not responsible for any damage or loss of data that might happen if you are using this script, which I doubt will ever happen. Use it at your own risk. Always make sure that you added the `tuntap` interface and the route before starting the proxy. Otherwise, you might end up not being able to use the proxy or the script.

Hope it helps someone who is also tired of those commands or too much in a rush of typing those commands. 
Planning on adding functionalities as I go because `ligolo-ng` is such a powerfull tool and makes a lot of things easier regarding pivoting.

Keep hacking and enjoy 😄

## Improvements
@TODO
This is not its final form, it can always get better.
* [x] Add a way to delete ligolo routes.
* [x] Add a verification/confirmation of the route input.
* [x] Do not start the `ligolo-proxy` without a new route on the interface.
* [x] Add a way to add a new route to the existing interface.
* [x] Add a way to add a new tuntap interface.
* [x] Add a way to delete a route from the existing interface.
* [x] Make a video demo

At this point, I am not sure if I will continue to improve this script.
I am open to suggestions and improvements. Feel free to open an issue or a pull request.
