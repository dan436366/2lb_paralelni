with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Unchecked_Deallocation;

procedure Min_Finder is

   ARRAY_SIZE : constant := 100_000_000;

   type Int_Array is array (Natural range <>) of Integer;
   type Int_Array_Access is access Int_Array;

   type Min_Element is record
      Value : Integer;
      Index : Natural;
   end record;

   package Random_Int is new Ada.Numerics.Discrete_Random (Integer);
   Gen : Random_Int.Generator;

   protected Global_Min_Manager is
      procedure Update (Local_Min : in Min_Element);
      function Get_Min return Min_Element;
   private
      Global_Min : Min_Element := (Value => Integer'Last, Index => 0);
   end Global_Min_Manager;

   protected body Global_Min_Manager is
      procedure Update (Local_Min : in Min_Element) is
      begin
         if Local_Min.Value < Global_Min.Value then
            Global_Min := Local_Min;
         end if;
      end Update;

      function Get_Min return Min_Element is
      begin
         return Global_Min;
      end Get_Min;
   end Global_Min_Manager;

   Array_Data : Int_Array_Access := null;

   function Generate_Array return Int_Array_Access is
      Result : Int_Array_Access := new Int_Array(0 .. ARRAY_SIZE - 1);
      Neg_Index : Natural;
   begin
      Random_Int.Reset(Gen);

      for I in Result'Range loop
         Result(I) := Random_Int.Random(Gen) mod 1_000_000;
      end loop;

      Neg_Index := Random_Int.Random(Gen) mod ARRAY_SIZE;
      Result(Neg_Index) := -(Random_Int.Random(Gen) mod 1000 + 1);

      return Result;
   end Generate_Array;

   task type Min_Finder_Task is
      entry Start(Start_Index, End_Index : in Natural);
   end Min_Finder_Task;

   task body Min_Finder_Task is
      Start_Idx, End_Idx : Natural;
      Local_Min : Min_Element := (Value => Integer'Last, Index => 0);
   begin
      accept Start(Start_Index, End_Index : in Natural) do
         Start_Idx := Start_Index;
         End_Idx := End_Index;
      end Start;

      for I in Start_Idx .. End_Idx loop
         if Array_Data(I) < Local_Min.Value then
            Local_Min := (Value => Array_Data(I), Index => I);
         end if;
      end loop;

      Global_Min_Manager.Update(Local_Min);
   end Min_Finder_Task;

   Num_Threads : Positive;
   Elements_Per_Thread : Natural;
   Result : Min_Element;

   procedure Free is new Ada.Unchecked_Deallocation (Int_Array, Int_Array_Access);

begin
   Array_Data := Generate_Array;

   Ada.Text_IO.Put("Enter number of threads: ");
   begin
      Ada.Integer_Text_IO.Get(Num_Threads);
      if Num_Threads <= 0 then
         Ada.Text_IO.Put_Line("Invalid number of threads, defaulting to 4");
         Num_Threads := 4;
      end if;
   exception
      when others =>
         Ada.Text_IO.Put_Line("Invalid input, defaulting to 4 threads");
         Num_Threads := 4;
   end;

   Elements_Per_Thread := ARRAY_SIZE / Num_Threads;

   declare
      Tasks : array (1 .. Num_Threads) of Min_Finder_Task;
   begin
      for I in Tasks'Range loop
         declare
            Start_Index : Natural := (I - 1) * Elements_Per_Thread;
            End_Index : Natural;
         begin
            if I = Num_Threads then
               End_Index := ARRAY_SIZE - 1;
            else
               End_Index := Start_Index + Elements_Per_Thread - 1;
            end if;

            Tasks(I).Start(Start_Index, End_Index);
         end;
      end loop;
   end;

   Result := Global_Min_Manager.Get_Min;

   Ada.Text_IO.Put("Minimum element: ");
   Ada.Integer_Text_IO.Put(Result.Value, Width => 0);
   Ada.Text_IO.Put(" at index: ");
   Ada.Integer_Text_IO.Put(Result.Index, Width => 0);
   Ada.Text_IO.New_Line;

   Free(Array_Data);

end Min_Finder;
