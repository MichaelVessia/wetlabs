#Wetlabs WQM Script

Format the output of a Wetlabs WQM into a useable CSV

##Basic Usage

Ensure that you have the data in a txt file.  See `example_input.txt`

Run the script with

```
ruby wqm.rb
```

The script will prompt you for a file name. Enter the name of the file, with the `.txt` extension included.

After execution completes, you should have a csv file in the same directory. It will have the same name as the input file, but with a `.csv` extension instead. See `example_output.csv`
