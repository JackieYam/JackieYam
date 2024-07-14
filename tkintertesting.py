import tkinter as tk
from tkinter import messagebox


class TradeManagementTool:
    def __init__(self, root):
        self.root = root
        self.root.title("Trade Management Tool")

        # Create main frame
        main_frame = tk.Frame(root, padx=10, pady=10)
        main_frame.pack(padx=10, pady=10)

        # Title
        title_label = tk.Label(main_frame, text="Trade Management", fg="black", font=("Arial", 14))
        title_label.grid(row=0, column=0, columnspan=4)

        # Create checkboxes for TP1, TP2, SL1, SL2
        self.tp1_var = tk.IntVar()
        self.tp2_var = tk.IntVar()
        self.sl1_var = tk.IntVar()
        self.sl2_var = tk.IntVar()

        self.create_checkbox(main_frame, "TP1", 1, self.tp1_var, self.toggle_tp1)
        self.create_checkbox(main_frame, "TP2", 2, self.tp2_var, self.toggle_tp2)
        self.create_checkbox(main_frame, "SL1", 3, self.sl1_var, self.toggle_sl1)
        self.create_checkbox(main_frame, "SL2", 4, self.sl2_var, self.toggle_sl2)

        # Create input fields and buttons
        self.tp_entry = self.create_button_field(main_frame, "TP", 5)
        self.sl_entry = self.create_button_field(main_frame, "SL", 6)
        self.se_entry = self.create_button_field(main_frame, "SE", 7)

        self.tp1_frame = self.create_button_field(main_frame, "TP1", 8, hidden=True)
        self.tp2_frame = self.create_button_field(main_frame, "TP2", 9, hidden=True)
        self.sl1_frame = self.create_button_field(main_frame, "SL1", 10, hidden=True)
        self.sl2_frame = self.create_button_field(main_frame, "SL2", 11, hidden=True)

        # Create close percentage fields
        self.close_percentage1_entry = self.create_percentage_field(main_frame, 8, hidden=True)
        self.close_percentage2_entry = self.create_percentage_field(main_frame, 9, hidden=True)
        self.close_percentage3_entry = self.create_percentage_field(main_frame, 10, hidden=True)
        self.close_percentage4_entry = self.create_percentage_field(main_frame, 11, hidden=True)

        # Create "SL in profit" checkbox
        self.sl_in_profit_var = tk.IntVar()
        self.sl_in_profit_check = tk.Checkbutton(main_frame, text="SL in profit", variable=self.sl_in_profit_var,
                                                 font=("Arial", 12))
        self.sl_in_profit_check.grid(row=7, column=2, columnspan=2)

        # Separator
        separator = tk.Frame(main_frame, height=2, bd=1, relief=tk.SUNKEN)
        separator.grid(row=12, column=0, columnspan=4, pady=5, sticky='ew')

        # Alert section
        alert_label = tk.Label(main_frame, text="Alert", fg="black", font=("Arial", 12))
        alert_label.grid(row=13, column=0, columnspan=4)

        self.create_alert_field(main_frame, "Price Above", 14)
        self.create_alert_field(main_frame, "Price Below", 15)

        # BE and close section
        self.be_entry = self.create_button_field(main_frame, "BE", 16)
        self.close_entry = self.create_button_field(main_frame, "CLOSE", 17)

    def create_checkbox(self, parent, label_text, column, var, command):
        checkbox = tk.Checkbutton(parent, text=label_text, variable=var, command=command, font=("Arial", 12))
        checkbox.grid(row=1, column=column)

    def create_button_field(self, parent, label_text, row, hidden=False, col_offset=0):
        frame = tk.Frame(parent, pady=5)
        if hidden:
            frame.grid(row=row, column=0, columnspan=4, sticky='ew')
            frame.grid_remove()
        else:
            frame.grid(row=row, column=0, columnspan=4, sticky='ew')

        button = tk.Button(frame, text=label_text, font=("Arial", 12))
        button.grid(row=0, column=0+col_offset, pady=5, sticky='e')

        entry = tk.Entry(frame, font=("Arial", 12))
        entry.grid(row=0, column=1+col_offset, pady=5, sticky='w')

        if label_text == "CLOSE":
            percent_label = tk.Label(frame, text="Close:", font=("Arial", 12))
            percent_label.grid(row=0, column=2+col_offset, sticky='e')

            entry_percent = tk.Entry(frame, font=("Arial", 12))
            entry_percent.grid(row=0, column=3+col_offset, pady=5, sticky='w')

            percent_sign = tk.Label(frame, text="%", font=("Arial", 12))
            percent_sign.grid(row=0, column=4+col_offset, sticky='w')

        return frame

    def create_percentage_field(self, parent, row, hidden=False, col_offset=0):
        if hidden:
            frame = tk.Frame(parent)
            frame.grid(row=row, column=2+col_offset, columnspan=2, sticky='ew')
            frame.grid_remove()
        else:
            frame = tk.Frame(parent, pady=5)
            frame.grid(row=row, column=2+col_offset, columnspan=2, sticky='ew')

        label = tk.Label(frame, text="Close:", font=("Arial", 12))
        label.grid(row=0, column=0, sticky='e')

        entry = tk.Entry(frame, font=("Arial", 12))
        entry.grid(row=0, column=1, pady=5, sticky='w')

        percent_label = tk.Label(frame, text="%", font=("Arial", 12))
        percent_label.grid(row=0, column=2, sticky='w')

        return frame

    def create_alert_field(self, parent, label_text, row):
        button = tk.Button(parent, text=label_text, font=("Arial", 12))
        button.grid(row=row, column=0, pady=5, sticky='e')

        entry = tk.Entry(parent, font=("Arial", 12))
        entry.grid(row=row, column=1, pady=5, sticky='w')

    def toggle_tp1(self):
        if self.tp1_var.get():
            self.tp1_frame.grid()
            self.close_percentage1_entry.grid()
        else:
            self.tp1_frame.grid_remove()
            self.close_percentage1_entry.grid_remove()

    def toggle_tp2(self):
        if self.tp2_var.get():
            self.tp2_frame.grid()
            self.close_percentage2_entry.grid()
        else:
            self.tp2_frame.grid_remove()
            self.close_percentage2_entry.grid_remove()

    def toggle_sl1(self):
        if self.sl1_var.get():
            self.sl1_frame.grid()
            self.close_percentage3_entry.grid()
        else:
            self.sl1_frame.grid_remove()
            self.close_percentage3_entry.grid_remove()

    def toggle_sl2(self):
        if self.sl2_var.get():
            self.sl2_frame.grid()
            self.close_percentage4_entry.grid()
        else:
            self.sl2_frame.grid_remove()
            self.close_percentage4_entry.grid_remove()


if __name__ == "__main__":
    root = tk.Tk()
    app = TradeManagementTool(root)
    root.mainloop()
