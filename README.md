# ftable

  ftable is a command line tool to print fomatted tables. It's written in Perl and it has no dependencies outside perl core modules.
  
  It does the following:
  
  * Allows you to select fields to be printed
  * Allows you to select the order in which fields will be printed
  * Allows you select the alignment which fields will be printed (left,center,right)
  * Allows you to print a nice ASCII table with borders or not

##Installation

Installing ftable is just a matter of downloading from github, making it executable and move somewhere into $PATH

```
wget https://raw.githubusercontent.com/tlopo/ftable/master/ftable.pl 
chmod +x ftable.pl
sudo mv ftable.pl /usr/local/bin/ftable
```

##Usage
```
Usage: ftable [OPTIONS] [FILE]

Options:
  -l, --left
        List of field numbers (separated by comma) to be left aligned

  -r, --right
        List of field numbers (separated by comma) to be right aligned

  -c, --center 
        List of field numbers (separated by comma) to be center aligned
        It is default if no alignmnet provided

  -p, --print
        List of field numbers (separated by comma) to be printed and ordered

  -n, --noborder 
        Do not print border

  -F, --field-separator
        Field separator, if no specified "comma" (,) is the default value
```

##Examples

ftable handles csv nicely, even when there are comma between quotes:
```
~# echo -e 'a,b,c\n"a,b,c",aaa,bbb' | ftable
+-------+-----+-----+
|   a   |  b  |  c  |
+-------+-----+-----+
| a,b,c | aaa | bbb |
+-------+-----+-----+
```

Print all fields centralized(default):
```
~# egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':' 
+----------+---+------+------+----------+--------------+-----------+
| www-data | x |  33  |  33  | www-data |   /var/www   |  /bin/sh  |
+----------+---+------+------+----------+--------------+-----------+
|  ubuntu  | x | 1000 | 1000 |  Ubuntu  | /home/ubuntu | /bin/bash |
+----------+---+------+------+----------+--------------+-----------+
```
Print all fields centralized without border:
```
~# egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':'  -n
 www-data  x   33    33   www-data    /var/www     /bin/sh  
  ubuntu   x  1000  1000   Ubuntu   /home/ubuntu  /bin/bash 
```

Print id,username and home dirs from /etc/passwd:
```
~# egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':' -p 3,1,6
+------+----------+--------------+
|  33  | www-data |   /var/www   |
+------+----------+--------------+
| 1000 |  ubuntu  | /home/ubuntu |
+------+----------+--------------+
```
Left align first field:

```
~# egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':' -p 3,1,6 -l 1
+------+----------+--------------+
| 33   | www-data |   /var/www   |
+------+----------+--------------+
| 1000 |  ubuntu  | /home/ubuntu |
+------+----------+--------------+

```
Right align first field and left align second field:
```
~# egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':' -p 3,1,6 -r 1 -l 2
+------+----------+--------------+
|   33 | www-data |   /var/www   |
+------+----------+--------------+
| 1000 | ubuntu   | /home/ubuntu |
+------+----------+--------------+
```
Left align first two fields:
```
egrep 'www-data|ubuntu' /etc/passwd | ftable -F ':' -p 3,1,6 -l 1,2
+------+----------+--------------+
| 33   | www-data |   /var/www   |
+------+----------+--------------+
| 1000 | ubuntu   | /home/ubuntu |
+------+----------+--------------+
```





