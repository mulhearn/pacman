#ifndef __IIC_H_
#define __IIC_H_

int init_iic();
void iic_menu();

void set_voltages(unsigned chan, unsigned vdda_up, unsigned vdda_dn,
		  unsigned vddd_up, unsigned vddd_dn);

void read_voltages();

#endif // __IIC_H_
