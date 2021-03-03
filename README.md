# I2C-Interface
Creating an interface for I2C communication to verify the functionality of an i2c master bus using systemverilog


Protocol definition and explanations are present in the docs folder as a pdf file. 
To run the code cd into the sim folder under project_benches and run make debug. (You need to have modelsim installed in your system). 

This project aims to verifiy the functionality of an i2c master bus that is connected to a wishbone interface which is used to interact with the master bus. An i2c slave is present on the next other side to provide the requested data and to read from the master bus when it wishes to write to the slave. 

The project verifies the read and the write capablities of the master bus by first writing 32 bytes of data continuously to the slave, the reading 32 bytes continuously from the slave and performing 64 alternating writes and reads. 

The project has only one i2c slave and can be extended by increasing the number of objects of the i2c interface that are created. 

The RTL for i2cmb is obtained from [www.opencores.org].
